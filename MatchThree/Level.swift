import Foundation

let numColumns = 9
let numRows = 9
let numLevels = 4 // Excluding level 0

class Level {
  
  private var tiles = Array2D<Tile>(columns: numColumns, rows: numRows)
  
  private var cookies = Array2D<Cookie>(columns: numColumns, rows: numRows)
  
  private var possibleSwaps: Set<Swap> = []
  
  var targetScore = 0
  var maximumMoves = 0
  
  private var comboMultiplier = 0
  
  init(filename: String) {
    // 1
    guard let levelData = LevelData.loadFrom(file: filename) else { return }
    // 2
    let tilesArray = levelData.tiles
    // 3
    for (row, rowArray) in tilesArray.enumerated() {
      // 4
      let tileRow = numRows - row - 1
      // 5
      for (column, value) in rowArray.enumerated() {
        if value == 1 {
          tiles[column, tileRow] = Tile()
        }
      }
    }
    
    targetScore = levelData.targetScore
    maximumMoves = levelData.moves
  }
  
  func tileAt(column: Int, row: Int) -> Tile? {
    precondition(column >= 0 && column < numColumns)
    precondition(row >= 0 && row < numRows)
    return tiles[column, row]
  }
  
  func cookie(atColumn column: Int, row: Int) -> Cookie? {
    precondition(column >= 0 && column < numColumns)
    precondition(row >= 0 && row < numRows)
    return cookies[column, row]
  }
  func shuffle() -> Set<Cookie> {
    var set: Set<Cookie>
    repeat {
      set = createInitialCookies()
      detectPossibleSwaps()
      print("possible swaps: \(possibleSwaps)")
    } while possibleSwaps.count == 0
    
    return set
  }
  private func createInitialCookies() -> Set<Cookie> {
    var set: Set<Cookie> = []
    
    // 1
    for row in 0..<numRows {
      for column in 0..<numColumns {
        if tiles[column, row] != nil {
          
          // Initialize cookie type
          var cookieType: CookieType
          
          // Randomly generate types until we're sure we don't set 3 of the same type in a row/column
          repeat {
            cookieType = CookieType.random()
          } while (column >= 2 &&
            cookies[column - 1, row]?.cookieType == cookieType &&
            cookies[column - 2, row]?.cookieType == cookieType)
            || (row >= 2 &&
              cookies[column, row - 1]?.cookieType == cookieType &&
              cookies[column, row - 2]?.cookieType == cookieType)
          
          // 3
          let cookie = Cookie(column: column, row: row, cookieType: cookieType)
          cookies[column, row] = cookie
          
          // 4
          set.insert(cookie)
        }
      }
    }
    return set
  }
  
  // Check if a cookie is in a chain (vertical or horizontal)
  private func hasChain(atColumn column: Int, row: Int) -> Bool {
    let cookieType = cookies[column, row]!.cookieType
    
    // Horizontal chain check
    var horizontalLength = 1
    
    // Left
    var i = column - 1
    while i >= 0 && cookies[i, row]?.cookieType == cookieType {
      i -= 1
      horizontalLength += 1
    }
    
    // Right
    i = column + 1
    while i < numColumns && cookies[i, row]?.cookieType == cookieType {
      i += 1
      horizontalLength += 1
    }
    
    // Return true if horizontal chain found
    if horizontalLength >= 3 { return true }
    
    // Vertical chain check
    var verticalLength = 1
    
    // Down
    i = row - 1
    while i >= 0 && cookies[column, i]?.cookieType == cookieType {
      i -= 1
      verticalLength += 1
    }
    
    // Up
    i = row + 1
    while i < numRows && cookies[column, i]?.cookieType == cookieType {
      i += 1
      verticalLength += 1
    }
    
    // Return true if vertical chain found
    return verticalLength >= 3
  }
  
  func detectPossibleSwaps() {
    var set: Set<Swap> = []
    
    for row in 0..<numRows {
      for column in 0..<numColumns {
        if let cookie = cookies[column, row] {
          
          // Have a cookie in this spot? If there is no tile, there is no cookie.
          
          // Column check
          if column < numColumns - 1, let other = cookies[column + 1, row] {
            
            // Swap them
            cookies[column, row] = other
            cookies[column + 1, row] = cookie
            
            // Is either cookie now part of a chain?
            if hasChain(atColumn: column + 1, row: row) || hasChain(atColumn: column, row: row) {
              set.insert(Swap(cookieA: cookie, cookieB: other))
            }
            
            // Swap them back
            cookies[column, row] = cookie
            cookies[column + 1, row] = other
          }
          
          // Row check
          if row < numRows - 1, let other = cookies[column, row + 1] {
            
            // Swap cookies
            cookies[column, row] = other
            cookies[column, row + 1] = cookie
            
            // Is either cookie now part of a chain?
            if hasChain(atColumn: column, row: row + 1) ||
              hasChain(atColumn: column, row: row) {
              set.insert(Swap(cookieA: cookie, cookieB: other))
            }
            
            // Swap them back
            cookies[column, row] = cookie
            cookies[column, row + 1] = other
          }
        }
          
        // Check last column
        else if column == numColumns - 1, let cookie = cookies[column, row] {
          if row < numRows - 1,
            let other = cookies[column, row + 1] {
            cookies[column, row] = other
            cookies[column, row + 1] = cookie
            
            // Is either cookie now part of a chain?
            if hasChain(atColumn: column, row: row + 1) ||
              hasChain(atColumn: column, row: row) {
              set.insert(Swap(cookieA: cookie, cookieB: other))
            }
            
            // Swap them back
            cookies[column, row] = cookie
            cookies[column, row + 1] = other
          }
        }
      }
    }
    
    possibleSwaps = set
  }
  
  func isPossibleSwap(_ swap: Swap) -> Bool {
    return possibleSwaps.contains(swap)
  }
  
  func performSwap(_ swap: Swap) {
    let columnA = swap.cookieA.column
    let rowA = swap.cookieA.row
    let columnB = swap.cookieB.column
    let rowB = swap.cookieB.row
    
    cookies[columnA, rowA] = swap.cookieB
    swap.cookieB.column = columnA
    swap.cookieB.row = rowA
    
    cookies[columnB, rowB] = swap.cookieA
    swap.cookieA.column = columnB
    swap.cookieA.row = rowB
  }
  
  private func detectHorizontalMatches() -> Set<Chain> {
    
    // create a new set to hold the horizontal chains
    var set: Set<Chain> = []
    
    // loop through the rows and columns
    for row in 0..<numRows {
      var column = 0
      
      // no need to look at the last two columns because these cookies can never begin a new chain
      while column < numColumns-2 {
        
        // skip over any gaps in the level design
        if let cookie = cookies[column, row] {
          let matchType = cookie.cookieType
          
          // check whether the next two columns have the same cookie type
          if cookies[column + 1, row]?.cookieType == matchType &&
            cookies[column + 2, row]?.cookieType == matchType {
            
            // got a chain
            let chain = Chain(chainType: .horizontal)
            
            // loop until we find a cookie with a different type or the end of the grid
            repeat {
              chain.add(cookie: cookies[column, row]!)
              column += 1
            } while column < numColumns && cookies[column, row]?.cookieType == matchType
            
            set.insert(chain)
            continue
          }
        }
        
        // if a chain is not found go to the following column
        column += 1
      }
    }
    return set
  }
  
  private func detectVerticalMatches() -> Set<Chain> {
    var set: Set<Chain> = []
    
    
    // loop through the columns and rows
    for column in 0..<numColumns {
      var row = 0
      
      // no need to look at the last two rows because these cookies can never begin a new chain
      while row < numRows-2 {
        
        // if it's a cookie and not a gap
        if let cookie = cookies[column, row] {
          let matchType = cookie.cookieType
          
          // check whether the next two rows have the same cookie type
          if cookies[column, row + 1]?.cookieType == matchType &&
            cookies[column, row + 2]?.cookieType == matchType {
            
            // got a chain
            let chain = Chain(chainType: .vertical)
            
            // loop until we find a cookie with a different type or the end of the grid
            repeat {
              chain.add(cookie: cookies[column, row]!)
              row += 1
            } while row < numRows && cookies[column, row]?.cookieType == matchType
            
            set.insert(chain)
            continue
          }
        }
        
        // if a chain is not found go to the following row
        row += 1
      }
    }
    return set
  }
  
  func removeMatches() -> Set<Chain> {
    let horizontalChains = detectHorizontalMatches()
    let verticalChains = detectVerticalMatches()
    
    removeCookies(in: horizontalChains)
    removeCookies(in: verticalChains)
    
    calculateScores(for: horizontalChains)
    calculateScores(for: verticalChains)
    
    return horizontalChains.union(verticalChains)
  }
  
  private func removeCookies(in chains: Set<Chain>) {
    for chain in chains {
      for cookie in chain.cookies {
        cookies[cookie.column, cookie.row] = nil
      }
    }
  }
  
  func fillHoles() -> [[Cookie]] {
    var columns: [[Cookie]] = []
    
    // loop through the columns
    for column in 0..<numColumns {
      var array: [Cookie] = []
      
      // loop through rows
      for row in 0..<numRows {
        
        // if there's a missing cookie
        if tiles[column, row] != nil && cookies[column, row] == nil {
          
          // scan upwards for existing cookies
          for lookup in (row + 1)..<numRows {
            
            // if cookie found
            if let cookie = cookies[column, lookup] {
              
              // fill the hole with it
              cookies[column, lookup] = nil
              cookies[column, row] = cookie
              cookie.row = row
              
              // add cookie to the list requiring animation
              array.append(cookie)
              
              // don't go further up
              break
            }
          }
        }
      }
      
      // append the column changes
      if !array.isEmpty {
        columns.append(array)
      }
    }
    
    // return moved cookies organized by column
    return columns
  }
  
  func topUpCookies() -> [[Cookie]] {
    var columns: [[Cookie]] = []
    var cookieType: CookieType = .unknown
    
    // loop through columns
    for column in 0..<numColumns {
      var array: [Cookie] = []
      
      // loop through rows from top to bottom
      var row = numRows - 1
      while row >= 0 && cookies[column, row] == nil {
        
        // skip level gaps
        if tiles[column, row] != nil {
          
          // create a random cookie but different from the previous one
          var newCookieType: CookieType
          repeat {
            newCookieType = CookieType.random()
          } while newCookieType == cookieType
          cookieType = newCookieType
          
          // create cookie and append it
          let cookie = Cookie(column: column, row: row, cookieType: cookieType)
          cookies[column, row] = cookie
          array.append(cookie)
        }
        
        row -= 1
      }
      // append new cookies per column
      if !array.isEmpty {
        columns.append(array)
      }
    }
    
    return columns
  }
  
  private func calculateScores(for chains: Set<Chain>) {
    // 3-chain is 60 pts, 4-chain is 120, 5-chain is 180, and so on
    for chain in chains {
      chain.score = 60 * (chain.length - 2) * comboMultiplier
      comboMultiplier += 1
    }
  }
  
  func resetComboMultiplier() {
    comboMultiplier = 1
  }
}
