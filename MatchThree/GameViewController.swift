import UIKit
import SpriteKit
import AVFoundation

class GameViewController: UIViewController {
  
  // MARK: Properties
  var level: Level!
  
  // The scene draws the tiles and cookie sprites, and handles swipes.
  var scene: GameScene!
  
  var movesLeft = 0
  var score = 0
  var currentLevelNumber = 1
  
  // MARK: IBOutlets
  @IBOutlet weak var gameOverPanel: UIImageView!
  @IBOutlet weak var targetLabel: UILabel!
  @IBOutlet weak var movesLabel: UILabel!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var shuffleButton: UIButton!
  
  var tapGestureRecognizer: UITapGestureRecognizer!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup view with level 1
    setupLevel(number: currentLevelNumber)
  }
  
  func setupLevel(number levelNumber: Int) {
    
    // Configure the view
    let skView = view as! SKView
    skView.isMultipleTouchEnabled = false
    
    // Create and configure the scene
    scene = GameScene(size: skView.bounds.size)
    scene.scaleMode = .aspectFill
    
    // Setup the level
    level = Level(filename: "Level_\(levelNumber)")
    scene.level = level
    
    // Add tiles
    scene.addTiles()
    
    // Swipe handler
    scene.swipeHandler = handleSwipe
    
    // Make sure the game over panel is hidden
    gameOverPanel.isHidden = true
    
    // Hide the shuffle button when starting the game
    shuffleButton.isHidden = true
    
    // Present the scene
    skView.presentScene(scene)
    
    // Start the game
    beginGame()
  }
  
  // MARK: IBActions
  @IBAction func shuffleButtonPressed(_: AnyObject) {
    shuffle()
    decrementMoves()
  }
  
  // MARK: View Controller Functions
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  override var shouldAutorotate: Bool {
    return true
  }
  
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return [.portrait, .portraitUpsideDown]
  }
  
  func beginGame() {
    movesLeft = level.maximumMoves
    score = 0
    updateLabels()
    
    level.resetComboMultiplier()
    
    scene.animateBeginGame {
      self.shuffleButton.isHidden = false
    }
    
    shuffle()
  }
  
  func shuffle() {
    scene.removeAllCookieSprites()
    
    let newCookies = level.shuffle()
    scene.addSprites(for: newCookies)
  }
  
  func handleSwipe(_ swap: Swap) {
    view.isUserInteractionEnabled = false
    
    if level.isPossibleSwap(swap) {
      level.performSwap(swap)
      scene.animate(swap, completion: handleMatches)
    } else {
      view.isUserInteractionEnabled = true
    }
  }
  
  func handleMatches() {
    
    // remove matches and store them
    let chains = level.removeMatches()
    
    // if no matches were removed begin next turn
    if chains.count == 0 {
      beginNextTurn()
      return
    }
    
    // animate matched cookies
    scene.animateMatchedCookies(for: chains) {
      
      // update score
      for chain in chains {
        self.score += chain.score
      }
      self.updateLabels()
      
      // frop existing cookies to fill holes
      let columns = self.level.fillHoles()
      
      // animate existing cookies falling
      self.scene.animateFallingCookies(in: columns) {
        
        // add new cookies to fill remaining holes
        let columns = self.level.topUpCookies()
        
        // animate new cookies falling
        self.scene.animateNewCookies(in: columns) {
          
          // repeat (chained scoring)
          self.handleMatches()
        }
      }
    }
  }
  
  func beginNextTurn() {
    level.resetComboMultiplier()
    level.detectPossibleSwaps()
    view.isUserInteractionEnabled = true
    decrementMoves()
  }
  
  func updateLabels() {
    targetLabel.text = String(format: "%ld", level.targetScore)
    movesLabel.text = String(format: "%ld", movesLeft)
    scoreLabel.text = String(format: "%ld", score)
  }
  
  func decrementMoves() {
    movesLeft -= 1
    updateLabels()
    
    if score >= level.targetScore {
      gameOverPanel.image = UIImage(named: "LevelComplete")
      currentLevelNumber = currentLevelNumber < numLevels ? currentLevelNumber + 1 : 1
      showGameOver()
    } else if movesLeft == 0 {
      gameOverPanel.image = UIImage(named: "GameOver")
      showGameOver()
    }
  }
  
  func showGameOver() {
    gameOverPanel.isHidden = false
    scene.isUserInteractionEnabled = false
    shuffleButton.isHidden = true
    
    scene.animateGameOver {
      self.tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.hideGameOver))
      self.view.addGestureRecognizer(self.tapGestureRecognizer)
    }
  }
  
  @objc func hideGameOver() {
    view.removeGestureRecognizer(tapGestureRecognizer)
    tapGestureRecognizer = nil
    
    gameOverPanel.isHidden = true
    scene.isUserInteractionEnabled = true
    
    setupLevel(number: currentLevelNumber)
  }
}
