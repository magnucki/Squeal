import Foundation

extension Database {
    
    public func prepareSelectFrom(from:        String,
                                  columns:     [String]? = nil,
                                  whereExpr:   String? = nil,
                                  groupBy:     String? = nil,
                                  having:      String? = nil,
                                  orderBy:     String? = nil,
                                  limit:       Int? = nil,
                                  offset:      Int? = nil,
                                  parameters:  [Bindable?] = [],
                                  error:       NSErrorPointer = nil) -> Statement? {
        
        var fragments = [ "SELECT" ]
        if columns != nil {
            fragments.append(join(",", columns!))
        } else {
            fragments.append("*")
        }
        
        fragments.append("FROM")
        fragments.append(from)
                            
        if whereExpr != nil {
            fragments.append("WHERE")
            fragments.append(whereExpr!)
        }
        
        if groupBy != nil {
            fragments.append("GROUP BY")
            fragments.append(groupBy!)
        }
        
        if having != nil {
            fragments.append("HAVING")
            fragments.append(having!)
        }
        
        if orderBy != nil {
            fragments.append("ORDER BY")
            fragments.append(orderBy!)
        }
        
        if limit != nil {
            fragments.append("LIMIT")
            fragments.append("\(limit)")
            
            if offset != nil {
                fragments.append("OFFSET")
                fragments.append("\(offset!)")
            }
        }
        
        var statement = prepareStatement(join(" ", fragments), error: error)
        if statement != nil && parameters.count > 0 {
            if false == statement!.bind(parameters, error:error) {
                statement!.close()
                statement = nil
            }
        }
        
        return statement
    }
    
    /// Selects table rows and iterates over them. This is a helper for executing a SELECT statement, and reading the
    /// results.
    ///
    /// Results are read by the `collector` block. The block will be invoked for each row of the result set, and is
    /// expected to return a value read from the row. It will be provided a Statement, from which the row can be read.
    ///
    /// :param: from        The name of the table to select from, including any JOIN clauses.
    /// :param: columns     The columns to select. These are not escaped, and can contain expressions. If nil, all
    ///                     columns are returned (e.g. '*').
    /// :param: whereExpr   The WHERE clause. If nil, then all rows are returned.
    /// :param: groupBy     The GROUP BY expression.
    /// :param: having      The HAVING clause.
    /// :param: orderBy     The ORDER BY clause.
    /// :param: limit       The LIMIT.
    /// :param: offset      The OFFSET.
    /// :param: parameters  An array of parameters to bind to the statement.
    /// :param: error       An error pointer.
    /// :param: collector   A block used to read each row.
    ///
    /// :returns:   An array of all values read, or nil if an error occurs.
    ///
    public func selectFrom<T>(from:        String,
                              columns:     [String]? = nil,
                              whereExpr:   String? = nil,
                              groupBy:     String? = nil,
                              having:      String? = nil,
                              orderBy:     String? = nil,
                              limit:       Int? = nil,
                              offset:      Int? = nil,
                              parameters:  [Bindable?] = [],
                              error:       NSErrorPointer = nil,
                              collector:   (Statement)->(T)) -> [T]? {
        
        if let statement = prepareSelectFrom(from,
                                             columns:   columns,
                                             whereExpr: whereExpr,
                                             groupBy:   groupBy,
                                             having:    having,
                                             orderBy:   orderBy,
                                             limit:     limit,
                                             offset:    offset,
                                             parameters:parameters,
                                             error:     error) {
                
            var values = statement.collect(error, collector:collector)
            statement.close()
            return values
                
        } else {
            return nil
        }
    }

    /// Counts rows in a table. This is a helper for executing a SELECT count(...) FROM statement and reading the
    /// result.
    ///
    /// :param: from        The name of the table to select from, including any JOIN clauses.
    /// :param: columns     The columns to count. If nil, then 'count(*)' is returned.
    /// :param: whereExpr   The WHERE clause. If nil, then all rows are returned.
    /// :param: parameters  An array of parameters to bind to the statement.
    /// :param: error       An error pointer.
    ///
    /// :returns:   The number of rows counted, or nil if an error occurs.
    ///
    public func countFrom(from:        String,
                          columns:     [String]? = nil,
                          whereExpr:   String? = nil,
                          parameters:  [Bindable?] = [],
                          error:       NSErrorPointer = nil) -> Int64? {

        let countExpr = "count(" + join(",", columns ?? ["*"]) + ")"
        if let statement = prepareSelectFrom(from,
                                             columns:   [countExpr],
                                             whereExpr: whereExpr,
                                             parameters:parameters,
                                             error:     error) {
            
            var count : Int64?
            switch statement.next(error) {
            case .Some(true):
                count = statement.int64ValueAtIndex(0)
            case .Some(false):
                count = 0
            default:
                break
            }

            statement.close()
            return count
        } else {
            return nil
        }
    }
    
}