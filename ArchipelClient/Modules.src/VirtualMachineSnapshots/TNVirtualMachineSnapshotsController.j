/*  
 * TNSampleTabModule.j
 *    
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import "TNSnapshot.j";
@import "TNSnapshotsDatasource.j";

/*! @defgroup  virtualmachinesnapshoting Module VirtualMachineSnapshoting
    @desc Module to handle Virtual Machine snapshoting
*/
TNArchipelPushNotificationSnapshoting       = @"archipel:push:snapshoting";
TNArchipelTypeHypervisorSnapshot            = @"archipel:virtualmachine:snapshoting";
TNArchipelTypeHypervisorSnapshotTake        = @"take";
TNArchipelTypeHypervisorSnapshotGet         = @"get";
TNArchipelTypeHypervisorSnapshotCurrent     = @"current";
TNArchipelTypeHypervisorSnapshotDelete      = @"delete";
TNArchipelTypeHypervisorSnapshotRevert      = @"revert";



/*! @ingroup virtualmachinesnapshoting
*/
@implementation TNVirtualMachineSnapshotsController : TNModule
{
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPScrollView                scrollViewSnapshots;
    @outlet CPSearchField               fieldFilter;
    @outlet CPTextField                 fieldInfo;
    @outlet CPTextField                 fieldJID;
    @outlet CPTextField                 fieldName;
    @outlet CPTextField                 fieldNewSnapshotName;
    @outlet CPView                      maskingView;
    @outlet CPView                      viewTableContainer;
    @outlet CPWindow                    windowNewSnapshot;
    @outlet LPMultiLineTextField        fieldNewSnapshotDescription;
    
    CPButton                            _minusButton;
    CPButton                            _plusButton;
    CPButton                            _revertButton;
    CPOutlineView                       _outlineViewSnapshots;
    TNSnapshot                          _currentSnapshot;
    TNSnapshotsDatasource               _datasourceSnapshots;
}

- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    
    // VM table view
    _datasourceSnapshots    = [[TNSnapshotsDatasource alloc] init];
    _outlineViewSnapshots   = [[CPOutlineView alloc] initWithFrame:[scrollViewSnapshots bounds]];

    [scrollViewSnapshots setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewSnapshots setAutohidesScrollers:YES];
    [scrollViewSnapshots setDocumentView:_outlineViewSnapshots];
    
    [_outlineViewSnapshots setUsesAlternatingRowBackgroundColors:YES];
    [_outlineViewSnapshots setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_outlineViewSnapshots setAllowsColumnResizing:YES];
    [_outlineViewSnapshots setAllowsEmptySelection:YES];
    [_outlineViewSnapshots setAllowsMultipleSelection:NO];
    [_outlineViewSnapshots setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    // [_outlineViewSnapshots setRowHeight:50.0];
    
    var outlineColumn = [[CPTableColumn alloc] initWithIdentifier:@"outline"];
    [outlineColumn setWidth:16];
    
    var columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[columnName headerView] setStringValue:@"UUID"];
    [columnName setWidth:100];
    [columnName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    var columnDescription = [[CPTableColumn alloc] initWithIdentifier:@"description"];
    [[columnDescription headerView] setStringValue:@"Description"];
    [columnDescription setWidth:400];
    [columnDescription setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"description" ascending:YES]];
    
    var columnCreationTime = [[CPTableColumn alloc] initWithIdentifier:@"creationTime"];
    [[columnCreationTime headerView] setStringValue:@"Creation date"];
    [columnCreationTime setWidth:130];
    [columnCreationTime setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"creationTime" ascending:YES]];
    
    var columnState     = [[CPTableColumn alloc] initWithIdentifier:@"isCurrent"];
    var imgView         = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [columnState setDataView:imgView];
    [columnState setResizingMask:CPTableColumnAutoresizingMask ];
    [columnState setWidth:16];
    [[columnState headerView] setStringValue:@""];    
    
    // [_outlineViewSnapshots addTableColumn:outlineColumn];
    [_outlineViewSnapshots addTableColumn:columnState];
    [_outlineViewSnapshots addTableColumn:columnDescription];
    [_outlineViewSnapshots addTableColumn:columnCreationTime];
    [_outlineViewSnapshots addTableColumn:columnName];
    [_outlineViewSnapshots setOutlineTableColumn:columnDescription];
    [_outlineViewSnapshots setDelegate:self];
    
    [_datasourceSnapshots setParentKeyPath:@"parent"];
    [_datasourceSnapshots setChildCompKeyPath:@"name"];
    [_datasourceSnapshots setSearchableKeyPaths:[@"name", @"description", @"creationTime"]];
    
    [fieldFilter setTarget:_datasourceSnapshots];
    [fieldFilter setAction:@selector(filterObjects:)];
    
    [_outlineViewSnapshots setDataSource:_datasourceSnapshots];
    
    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Create new snapshot" action:@selector(openWindowNewSnapshot:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Delete" action:@selector(deleteSnapshot:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Restore" action:@selector(restoreSnapshot:) keyEquivalent:@""];
    [_outlineViewSnapshots setMenu:menu];
    
    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-photo-add.png"] size:CPSizeMake(16, 16)]];
    [_plusButton setAction:@selector(openWindowNewSnapshot:)];
    
    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-photo-remove.png"] size:CPSizeMake(16, 16)]];
    [_minusButton setAction:@selector(deleteSnapshot:)];
    
    _revertButton = [CPButtonBar minusButton];
    [_revertButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-revert.png"] size:CPSizeMake(16, 16)]];
    [_revertButton setTarget:self];
    [_revertButton setAction:@selector(revertSnapshot:)];
    
    [_revertButton setEnabled:NO];
    [_minusButton setEnabled:NO];
    
    [buttonBarControl setButtons:[_plusButton, _minusButton, _revertButton]];
}

- (void)willLoad
{
    [super willLoad];
    
    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [self registerSelector:@selector(didPushReceived:) forPushNotificationType:TNArchipelPushNotificationSnapshoting];
    
    _currentSnapshot = nil;
    
    [_outlineViewSnapshots setDelegate:nil];
    [_outlineViewSnapshots setDelegate:self];
    
    [self checkIfRunning];
    [self getSnapshots:nil];
}

- (void)willUnload
{
    [super willUnload];
    
    [_datasourceSnapshots removeAllObjects];
    [_outlineViewSnapshots reloadData];
    [_outlineViewSnapshots deselectAll];
    [_revertButton setEnabled:NO];
    [_minusButton setEnabled:NO];
}

- (void)willShow
{
    [super willShow];
    [self checkIfRunning];
}

- (void)willHide
{
    [super willHide];
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}


- (BOOL)didPushReceived:(TNStropheStanza)aStanza
{
    var sender = [aStanza getFromNode].split("/")[0];
    var change = [aStanza valueForAttribute:@"change"];
    
    CPLog.info("receiving push notification TNArchipelPushNotificationSnapshoting with change " + change);
    
    [self getSnapshots:nil];
    
    return YES;
}

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    [self checkIfRunning];
}

- (void)checkIfRunning
{
    if ([_entity status] == TNStropheContactStatusOnline || [_entity status] == TNStropheContactStatusAway)
    {
        [maskingView removeFromSuperview];
    }
    else
    {
        [maskingView setFrame:[[self view] bounds]];
        [[self view] addSubview:maskingView];
    }
}


- (IBAction)openWindowNewSnapshot:(id)sender
{
    [fieldNewSnapshotName setStringValue:@""];
    [fieldNewSnapshotDescription setStringValue:@""];
    [windowNewSnapshot center];
    [windowNewSnapshot makeFirstResponder:fieldNewSnapshotDescription];
    [fieldNewSnapshotName setStringValue:[CPString UUID]];
    [windowNewSnapshot makeKeyAndOrderFront:sender];
    
}

- (IBAction)getSnapshots:(id)sender
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotGet}];

    [self sendStanza:stanza andRegisterSelector:@selector(didGetSnapshots:)];
}

- (void)didGetSnapshots:(id)aStanza
{
    if ([aStanza getType] == @"result")
    {
        var snapshots = [aStanza childrenWithName:@"domainsnapshot"];
        
        [_datasourceSnapshots removeAllObjects];
        
        for (var i = 0; i < [snapshots count]; i++)
        {
            var snapshot        = [snapshots objectAtIndex:i];
            var snapshotObject  = [[TNSnapshot alloc] init];
            var date            = [CPDate dateWithTimeIntervalSince1970:[[snapshot firstChildWithName:@"creationTime"] text]];

            CPLog.debug([[snapshot firstChildWithName:@"domainsnapshot"] text]);
            
            [snapshotObject setUUID:[[snapshot firstChildWithName:@"uuid"] text]];
            [snapshotObject setName:[[snapshot firstChildWithName:@"name"] text]];
            [snapshotObject setDescription:[[snapshot firstChildWithName:@"description"] text]];
            [snapshotObject setCreationTime:date.dateFormat(@"Y-m-d H:i:s")];
            [snapshotObject setState:[[snapshot firstChildWithName:@"state"] text]];
            [snapshotObject setParent:[[[snapshot firstChildWithName:@"parent"] firstChildWithName:@"name"] text]];
            [snapshotObject setDomain:[[snapshot firstChildWithName:@"domain"] text]];
            [snapshotObject setCurrent:NO];
            
            [_datasourceSnapshots addObject:snapshotObject];
        }
        
        [self getCurrentSnapshot:nil];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (IBAction)getCurrentSnapshot:(id)sender
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotCurrent}];

    [self sendStanza:stanza andRegisterSelector:@selector(didGetCurrentSnapshot:)];
}


- (IBAction)didGetCurrentSnapshot:(TNStropheStanza)aStanza
{
    [fieldInfo setStringValue:@""];
    if ([aStanza getType] == @"result")
    {
        var snapshots   = [aStanza firstChildWithName:@"domainsnapshot"];
        var name        = [[snapshots firstChildWithName:@"name"] text];
        
        for (var i = 0; i < [_datasourceSnapshots count]; i++)
        {
            var obj = [_datasourceSnapshots objectAtIndex:i];
            
            if ([obj name] == name)
            {
                _currentSnapshot = obj;
                [obj setCurrent:YES];
                break;
            }
            
        }
    }
    else if ([aStanza getType] == @"ignore")
    {
        [fieldInfo setStringValue:@"There is no snapshot for this virtual machine"];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
    
    [_outlineViewSnapshots reloadData];
    [_outlineViewSnapshots expandAll];
}


//actions
- (IBAction)takeSnapshot:(id)sender
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];
    var uuid    = [CPString UUID];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotTake}];

    [stanza addChildName:@"domainsnapshot"];

    [stanza addChildName:@"name"];
    [stanza addTextNode:[fieldNewSnapshotName stringValue]];
    [stanza up];

    [stanza addChildName:@"description"];
    [stanza addTextNode:[[fieldNewSnapshotDescription stringValue] stringByReplacingOccurrencesOfString:@"\n" withString:@""]];
    //[stanza addTextNode:[fieldNewSnapshotDescription stringValue]];
    [stanza up];    
    
    [self sendStanza:stanza andRegisterSelector:@selector(didTakeSnapshot:)];
    
    [windowNewSnapshot orderOut:nil];
    [fieldNewSnapshotName setStringValue:nil];
    [fieldNewSnapshotDescription setStringValue:nil];
}

- (void)didTakeSnapshot:(id)aStanza
{
    if ([aStanza getType] == @"result")
    {        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Snapshot" message:@"Snapshoting sucessfull"];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (IBAction)deleteSnapshot:(id)sender
{
    var selectedIndexes = [_outlineViewSnapshots selectedRowIndexes];
    
    if ([selectedIndexes count] > 1)
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Snapshot" message:@"You must select only one snapshot" icon:TNGrowlIconError];
        return;
    }
                    
    var alert = [TNAlert alertWithTitle:@"Delete to snapshot"
                                message:@"Are you sure you want to destory this snapshot ? this is not reversible."
                                delegate:self
                                 actions:[["Delete", @selector(performDeleteSnapshot:)], ["Cancel", nil]]];
    [alert runModal];
}


- (void)performDeleteSnapshot:(id)someUserInfo
{
    var selectedIndexes = [_outlineViewSnapshots selectedRowIndexes];
    var stanza          = [TNStropheStanza iqWithType:@"set"];
    var object          = [_outlineViewSnapshots itemAtRow:[selectedIndexes firstIndex]];
    var name            = [object name];
    
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotDelete,
        "name": name}];

    [self sendStanza:stanza andRegisterSelector:@selector(didDeleteSnapshot:)];

}

- (void)didDeleteSnapshot:(id)aStanza
{
    if ([aStanza getType] == @"result")
    {        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Snapshot" message:@"Snapshot deleted"];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)revertSnapshot:(id)sender
{
    if ([_outlineViewSnapshots numberOfSelectedRows] == 0)
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Snapshot" message:@"You must select one snapshot" icon:TNGrowlIconError];
        return;
    }
    
    var alert = [TNAlert alertWithTitle:@"Revert to snapshot"
                                message:@"Are you sure you want to revert to this snasphot ? All unsnapshoted changes will be lost."
                                delegate:self
                                 actions:[["Revert", @selector(performRevertSnapshot:)], ["Cancel", nil]]];
    [alert runModal];
}

- (void)performRevertSnapshot:(id)someUserInfo
{
    var stanza          = [TNStropheStanza iqWithType:@"set"];
    var selectedIndexes   = [_outlineViewSnapshots selectedRowIndexes];
    
    if ([selectedIndexes count] > 1)
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Snapshot" message:@"You must select only one snapshot" icon:TNGrowlIconError];
        return;
    }
    
    var object  = [_outlineViewSnapshots itemAtRow:[selectedIndexes firstIndex]];
    var name    = [object name];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorSnapshot}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorSnapshotRevert,
        "name": name}];
           
    [self sendStanza:stanza andRegisterSelector:@selector(didRevertSnapshot:)];
}

- (void)didRevertSnapshot:(id)aStanza
{
    if ([aStanza getType] == @"result")
    {        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Snapshot" message:@"Snapshot sucessfully reverted"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}



- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    [_revertButton setEnabled:NO];
    [_minusButton setEnabled:NO];
    
    if ([_outlineViewSnapshots numberOfSelectedRows] > 0)
    {
        [_minusButton setEnabled:YES];
        [_revertButton setEnabled:YES];
    }
}

- (int)tableView:(CPTableView)aTableView heightOfRow:(int)aRow
{
    // FIXME : wait for Cappuccino to implement this.
    return 10.0;
}

@end



