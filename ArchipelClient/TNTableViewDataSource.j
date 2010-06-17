/*  
 * TNTableDataSource.j
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


@implementation TNTableViewDataSource: CPObject
{
    CPArray         _content                @accessors(property=content);
    CPArray         _searchableKeyPaths     @accessors(property=searchableKeyPaths);
    CPTableView     _table                  @accessors(property=table);
    
    CPArray         _filteredContent;
    CPSearchField   _searchField;
    CPString        _filter;
}

- (id)init
{
    if (self = [super init])
    {
        _content            = [CPArray array];
        _filteredContent    = [CPArray array];
        _searchableKeyPaths = [CPArray array];
        
        _filter             = @"";
    }
    return self;
}

- (IBAction)filterObjects:(id)sender
{
    if (!_searchField)
        _searchField = sender;
    
    
    _filteredContent = [CPArray array];
    _filter          = [[sender stringValue] uppercaseString];

    if (!(_filter) || (_filter == @""))
    {
        _filteredContent = [_content copy];
        [_table reloadData];
        return;
    }

    for(var i = 0; i < [_content count]; i++)
    {
        var entry = [_content objectAtIndex:i];
        
        for (var j = 0; j < [_searchableKeyPaths count]; j++)
        {
            var entryValue = [entry valueForKeyPath:[_searchableKeyPaths objectAtIndex:j]];
            
            if ([entryValue uppercaseString].indexOf(_filter) != -1)
            {
                if (![_filteredContent containsObject:entry])
                    [_filteredContent addObject:entry];
            }
                
        }
    }
    
    [_table reloadData];
}

// Datasource impl.
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    return [_filteredContent count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    return [[_filteredContent objectAtIndex:aRow] valueForKey:identifier];
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    var indexes         = [aTableView selectedRowIndexes];
    var selectedObjects = [_filteredContent objectsAtIndexes:indexes];
    
    [_filteredContent sortUsingDescriptors:[aTableView sortDescriptors]];
    [_content sortUsingDescriptors:[aTableView sortDescriptors]];
    
    [_table reloadData];
    
    var indexesToSelect = [[CPIndexSet alloc] init];
    
    for (var i = 0; i < [selectedObjects count]; i++)
    {
        var object = [selectedObjects objectAtIndex:i];
        [indexesToSelect addIndex:[_filteredContent indexOfObject:object]];
    }
    
    [_table selectRowIndexes:indexesToSelect byExtendingSelection:NO];
    
}

- (void)tableView:(CPTableView)aTableView setObjectValue:(id)aValue forTableColumn:(CPTableColumn)aCol row:(int)aRow
{
    var identifier = [aCol identifier];

    [[_filteredContent objectAtIndex:aRow] setValue:aValue forKey:identifier];
}

- (void)addObject:(id)anObject
{
    _filter = @"";
    
    if (_searchField)
        [_searchField setStringValue:@""];
    
    [_content addObject:anObject];
    [_filteredContent addObject:anObject];
}

- (void)objectAtIndex:(int)index
{
    return [_filteredContent objectAtIndex:index];   
}

- (void)removeObjectAtIndex:(int)index
{
    var object = [_filteredContent objectAtIndex:index];

    [_filteredContent removeObjectAtIndex:index];
    [_content removeObject:object];
}

- (void)removeAllObjects
{
    [_content removeAllObjects];
    [_filteredContent removeAllObjects];
}

- (int)count
{
    return [_filteredContent count];
}

- (void)setContent:(CPArray)aContent
{
    _filter = @"";
    if (_searchField)
        [_searchField setStringValue:@""];
    
    _content = [aContent copy];
    _filteredContent = [aContent copy];
}

- (void)removeObjectsAtIndexes:(CPIndexSet)aSet
{
    try
    {
        var objects = [_filteredContent objectsAtIndexes:aSet];

        [_filteredContent removeObjectsAtIndexes:aSet];
        [_content removeObjectsInArray:objects];
    }
    catch(e)
    {
        CPLog.error(e);
    }
}

- (CPArray)objectsAtIndexes:(CPIndexSet)aSet
{
    return [_filteredContent objectsAtIndexes:aSet];
}

-(void)indexOfObject:(id)anObject
{
    return [_filteredContent indexOfObject:anObject];
}

@end