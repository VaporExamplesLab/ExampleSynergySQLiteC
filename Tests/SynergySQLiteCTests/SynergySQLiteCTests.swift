import XCTest
@testable import SynergySQLiteC

final class SynergySQLiteCTests: XCTestCase {
    func testExample() {
        print("\nSynergySQLiteCTests.testExample()")
        print("SQLITE_OK=\(SQLITE_OK)")
        print("SQLITE_UTF8=\(SQLITE_UTF8)")
        print("SQLITE_VERSION=\(SQLITE_VERSION)")
        print("SQLITE_VERSION_NUMBER=\(SQLITE_VERSION_NUMBER)")
        print("SQLITE_SOURCE_ID=\(SQLITE_SOURCE_ID)\n")
    }
    
    // SQLite READABLE typedef
    typealias sqlite3 = OpaquePointer
    typealias CCharPointer = UnsafeMutablePointer<CChar>
    // SQLite in memory database
    let filename = ":memory:"
    let sql = "SELECT sqlite_version()"
    
    let sqlDateTimeDefault = "SELECT CURRENT_TIMESTAMP"
    let sqlDateTimeNow = "SELECT datetime('now')"
    let sqlDateTimeMilliSec = "SELECT strftime('%Y-%m-%d %H:%M:%f ', 'now')"
    let sqlDateTimeJsonZulu = "SELECT strftime('%Y-%m-%dT%H:%M:%SZ', 'now')"
    let sqlUnixEpochSeconds = "SELECT strftime('%s','now')"
    /// sqlTimeIntervalSince1970 is like Swift Foundation `Date` `timeIntervalSince1970` in seconds
    let sqlUnixEpochMilliSec = "SELECT (julianday('now') - 2440587.5)*86400.0"
    
    func sqlQuery(path: String, sql: String) -> [String] {
        var db: OpaquePointer? = nil
        var statement: OpaquePointer? = nil // statement byte code
        var result = [String]()
        
        // Open Database
        if let cFileName: [CChar] = path.cString(using: String.Encoding.utf8) {
            let openMode: Int32 = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
            let statusOpen = sqlite3_open_v2(
                cFileName, // filename: UnsafePointer<CChar> … UnsafePointer<Int8>
                &db,       // ppDb: UnsafeMutablePointer<OpaquePointer?> aka handle
                openMode,  // flags: Int32 
                nil        // zVfs VFS module name: UnsafePointer<CChar> … UnsafePointer<Int8>
            )
            if statusOpen != SQLITE_OK {
                print("error opening database")
                return result
            }
        }
        
        // A: Prepare SQL Statement. Compile SQL text to byte code object.
        let statusPrepare = sqlite3_prepare_v2(
            db,         // sqlite3 *db          : Database handle
            sql,        // const char *zSql     : SQL statement, UTF-8 encoded
            -1,         // int nByte            : -1 to first zero terminator | zSql max bytes
            &statement, // qlite3_stmt **ppStmt : OUT: Statement byte code handle
            nil         // const char **pzTail  : OUT: unused zSql pointer
        ) 
        if statusPrepare != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("error preparing compiled statement: \(errmsg)")
            return result
        }
        
        // B: Bind. This example does not bind any parameters
        
        // C: Column Step.  Interate through columns.
        var statusStep = sqlite3_step(statement)
        while statusStep == SQLITE_ROW {
            
            print("-- ROW --")
            for i in 0 ..< sqlite3_column_count(statement) { 
                let cp = sqlite3_column_name(statement, i)
                let columnName = String(cString: cp!)
                
                switch sqlite3_column_type(statement, i) {
                case SQLITE_BLOB:
                    print("SQLITE_BLOB:    \(columnName)")
                case SQLITE_FLOAT:  
                    let v: Double = sqlite3_column_double(statement, i)
                    print("SQLITE_FLOAT:   \(columnName)=\(v)")
                    result.append(String(v))
                case SQLITE_INTEGER:
                    // let v:Int32 = sqlite3_column_int(statement, i)
                    let v: Int64 = sqlite3_column_int64(statement, i)
                    print("SQLITE_INTEGER: \(columnName)=\(v)")
                    result.append(String(v))
                case SQLITE_NULL:  
                    print("SQLITE_NULL:    \(columnName)")
                    result.append("NULL")
                case SQLITE_TEXT: // SQLITE3_TEXT
                    if let v = sqlite3_column_text(statement, i) {
                        let s = String(cString: v)
                        print("SQLITE_TEXT:    \(columnName)=\(s)")
                        result.append(s)
                    } 
                    else {
                        print("SQLITE_TEXT: not convertable")
                    }            
                default:
                    print("sqlite3_column_type not found")
                    break
                }
            }
            
            // next step
            statusStep = sqlite3_step(statement)
        }
        if statusStep != SQLITE_DONE {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("failure inserting foo: \(errmsg)")
        }
        
        // D. Deallocate. Release statement object.
        if sqlite3_finalize(statement) != SQLITE_OK {
            let errmsg = String(cString: sqlite3_errmsg(db))
            print("error finalizing prepared statement: \(errmsg)")
        }
        
        // Close Database
        if sqlite3_close_v2(db) != SQLITE_OK {
            print("error closing database")
        }
        
        return result
    }
    
    /// Verify C Query version (run time) matches sqlite3.h header (compile time) version 
    func testVersion() {
        var result: [String] = sqlQuery(path: filename, sql: sql)
        print(result[0])
        
        XCTAssert(SQLITE_VERSION == result[0])
        
        result = sqlQuery(path: filename, sql: sqlDateTimeDefault)
        print(result[0])
        result = sqlQuery(path: filename, sql: sqlDateTimeNow)
        print(result[0])
        result = sqlQuery(path: filename, sql: sqlDateTimeMilliSec)
        print(result[0])
        result = sqlQuery(path: filename, sql: sqlDateTimeJsonZulu)
        print(result[0])
        result = sqlQuery(path: filename, sql: sqlUnixEpochSeconds)
        print(result[0])
        result = sqlQuery(path: filename, sql: sqlUnixEpochMilliSec)
        print(result[0])
    }

    static var allTests = [
        ("testExample", testExample),
        ("testVersion", testVersion),
    ]
}
