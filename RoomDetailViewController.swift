import UIKit

class RoomDetailViewController: UIViewController {
    
    @IBOutlet weak var myBalance: UILabel! // 현재 나의 잔액
    @IBOutlet weak var pageChangeView: UIView! // 화면이 바뀌는 부분
    @IBOutlet weak var pageControl: UIPageControl! // 페이지컨트롤
    
    // 🔥 전달받을 roomID 변수
    var receivedRoomID: String?
    
    // 🔥 방 데이터 및 사용자 정보
    var currentRoom: Room?
    var currentUserID: String!
    var isOwner: Bool = false
    
    // 자식 뷰 컨트롤러들
    var stepOneController: StepOneController?
    // 나머지는 임시로 주석 처리
    
    var stepTwoController: StepTwoController?
    
    var stepThreeController: StepThreeController?
    var stepFourController: StepFourController?
    var stepFiveController: StepFiveController?
    var stepSixController: StepSixController?
    var stepSevenController: StepSevenController?
    
    
    var currentChildViewController: UIViewController?
    var currentStep: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 RoomDetailViewController 로드 시작")
        
        setupUI()
        loadUserInfo()
        loadRoomData()
        
        print("✅ RoomDetailViewController 로드 완료")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 탭바 숨기기
        self.tabBarController?.tabBar.isHidden = true
        pageControl.isHidden = true
        // 페이지 컨트롤 설정
        pageControl.numberOfPages = 7
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.systemGray4
        pageControl.currentPageIndicatorTintColor = UIColor.systemOrange
        pageControl.isUserInteractionEnabled = false // 직접 탭 비활성화
        
        // 네비게이션 설정
        navigationItem.title = "방 입장"
        
        print("✅ UI 설정 완료")
    }
    
    // MARK: - 사용자 정보 로드
    private func loadUserInfo() {
        currentUserID = UserDefaults.standard.string(forKey: "currentUserID")
        
        // 사용자 잔액 업데이트
        if let user = CoreDataManager.shared.getUser(userID: currentUserID) {
            myBalance.text = "잔액: \(NumberFormatter.localizedString(from: NSNumber(value: user.balance), number: .decimal))원"
        }
        
        print("✅ 사용자 정보 로드 완료 - ID: \(currentUserID ?? "")")
    }
    
    // MARK: - 방 데이터 로드
    private func loadRoomData() {
        guard let roomID = receivedRoomID else {
            print("❌ roomID가 없어서 데이터를 로드할 수 없습니다")
            return
        }
        
        // 🔥 Core Data에서 방 정보 가져오기
        if let room = CoreDataManager.shared.getRoom(roomID: roomID) {
            currentRoom = room
            
            // 방장인지 확인
            isOwner = (room.ownerID == currentUserID)
            
            print("✅ 방 데이터 로드 성공:")
            print("   - 방 ID: \(room.roomID ?? "")")
            print("   - 방장: \(room.ownerID ?? "")")
            print("   - 현재 사용자가 방장인가: \(isOwner)")
            print("   - 출발지: \(room.startLocation ?? "")")
            print("   - 목적지: \(room.endLocation ?? "")")
            print("   - 현재인원: \(room.currentMembers)/\(room.maxMembers)")
            print("   - 상태: \(room.status ?? "")")
            print("   - 예상비용: \(Int(room.estimatedCost))원")
            print("   - 인당비용: \(room.costPerPerson)원")
            
            // Step 1 화면 표시
            showStepOne()
            
        } else {
            print("❌ 방 데이터를 찾을 수 없습니다: \(roomID)")
            
            let alert = UIAlertController(
                title: "오류",
                message: "방 정보를 불러올 수 없습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                self.navigationController?.popViewController(animated: true)
            })
            present(alert, animated: true)
        }
    }
    
    // MARK: - Step 페이지 전환 관리
    private func showStepOne() {
        removeCurrentChild()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let stepOneVC = storyboard.instantiateViewController(withIdentifier: "StepOneController") as? StepOneController {
            stepOneVC.parentRoomDetail = self // 부모 참조 설정
            addChildViewController(stepOneVC, to: pageChangeView)
            stepOneController = stepOneVC
            
            currentStep = 1
            pageControl.currentPage = 0
            
            print("📱 Step 1 페이지 표시")
        } else {
            print("❌ StepOneController를 찾을 수 없습니다")
        }
    }
    
    func showStepTwo() {
            print("📱 Step 2 페이지 표시 시작")
            
            removeCurrentChild()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let stepTwoVC = storyboard.instantiateViewController(withIdentifier: "StepTwoController") as? StepTwoController {
                stepTwoVC.parentRoomDetail = self // 부모 참조 설정
                addChildViewController(stepTwoVC, to: pageChangeView)
                stepTwoController = stepTwoVC
                
                currentStep = 2
                pageControl.currentPage = 1
                
                // 네비게이션 타이틀 변경
                navigationItem.title = "출발지로 모여주세요"
             
                print("✅ Step 2 페이지 표시 완료")
            } else {
                print("❌ StepTwoController를 찾을 수 없습니다")
            }
        }
        
    
    func showStepThree() {
            print("📱 Step 3 페이지 표시 시작")
            
            removeCurrentChild()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let stepThreeVC = storyboard.instantiateViewController(withIdentifier: "StepThreeController") as? StepThreeController {
                stepThreeVC.parentRoomDetail = self
                addChildViewController(stepThreeVC, to: pageChangeView)
                stepThreeController = stepThreeVC
                
                currentStep = 3
                pageControl.currentPage = 2
                
                navigationItem.title = "택시 검색 중..."
                
                print("✅ Step 3 페이지 표시 완료")
            } else {
                print("❌ StepThreeController를 찾을 수 없습니다")
            }
        }
        
        // 3. 🔥 showStepFour() 메서드 완전히 교체
        func showStepFour() {
            print("📱 Step 4 페이지 표시 시작")
            
            removeCurrentChild()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let stepFourVC = storyboard.instantiateViewController(withIdentifier: "StepFourController") as? StepFourController {
                stepFourVC.parentRoomDetail = self
                addChildViewController(stepFourVC, to: pageChangeView)
                stepFourController = stepFourVC
                
                currentStep = 4
                pageControl.currentPage = 3
                
                navigationItem.title = "기사님 매칭 중..."
                
                print("✅ Step 4 페이지 표시 완료")
            } else {
                print("❌ StepFourController를 찾을 수 없습니다")
            }
        }
        
        // 4. 🔥 showStepFive() 메서드 완전히 교체
        func showStepFive() {
            print("📱 Step 5 페이지 표시 시작")
            
            removeCurrentChild()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let stepFiveVC = storyboard.instantiateViewController(withIdentifier: "StepFiveController") as? StepFiveController {
                stepFiveVC.parentRoomDetail = self
                addChildViewController(stepFiveVC, to: pageChangeView)
                stepFiveController = stepFiveVC
                
                currentStep = 5
                pageControl.currentPage = 4
                
                navigationItem.title = "기사님 매칭 완료!"
                
                print("✅ Step 5 페이지 표시 완료")
            } else {
                print("❌ StepFiveController를 찾을 수 없습니다")
            }
        }
        
        // 5. 🔥 showStepSix() 메서드 완전히 교체
        func showStepSix() {
            print("📱 Step 6 페이지 표시 시작")
            
            removeCurrentChild()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let stepSixVC = storyboard.instantiateViewController(withIdentifier: "StepSixController") as? StepSixController {
                stepSixVC.parentRoomDetail = self
                addChildViewController(stepSixVC, to: pageChangeView)
                stepSixController = stepSixVC
                
                currentStep = 6
                pageControl.currentPage = 5
                
                navigationItem.title = "탑승 중..."
                
                print("✅ Step 6 페이지 표시 완료")
            } else {
                print("❌ StepSixController를 찾을 수 없습니다")
            }
        }
        
        // 6. 🔥 showStepSeven() 메서드 완전히 교체
        func showStepSeven() {
            print("📱 Step 7 페이지 표시 시작")
            
            removeCurrentChild()
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let stepSevenVC = storyboard.instantiateViewController(withIdentifier: "StepSevenController") as? StepSevenController {
                stepSevenVC.parentRoomDetail = self
                addChildViewController(stepSevenVC, to: pageChangeView)
                stepSevenController = stepSevenVC
                
                currentStep = 7
                pageControl.currentPage = 6
                
                navigationItem.title = "요금 정산"
                
                print("✅ Step 7 페이지 표시 완료")
            } else {
                print("❌ StepSevenController를 찾을 수 없습니다")
            }
        }
       
        
    
    // MARK: - 자식 뷰 컨트롤러 관리
    private func addChildViewController(_ child: UIViewController, to containerView: UIView) {
        addChild(child)
        containerView.addSubview(child.view)
        
        // Auto Layout 설정
        child.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        child.didMove(toParent: self)
        currentChildViewController = child
    }
    
    private func removeCurrentChild() {
        currentChildViewController?.willMove(toParent: nil)
        currentChildViewController?.view.removeFromSuperview()
        currentChildViewController?.removeFromParent()
        currentChildViewController = nil
    }
    
    // MARK: - Step1에서 호출할 메서드들
    func handleStartButtonClicked() {
        print("🚀 시작 버튼 클릭 - Step 2로 이동")
        showStepTwo()
    }
    
    func handleExitButtonClicked() {
        print("🚪 나가기 버튼 클릭")
        
        // 방에서 나가기 처리
        if let roomID = receivedRoomID {
            let success = CoreDataManager.shared.leaveRoom(roomID: roomID, userID: currentUserID)
            
            if success {
                print("✅ 방 나가기 성공")
            } else {
                print("❌ 방 나가기 실패")
            }
        }
        
        // RoomList로 돌아가기 (TabBar의 두 번째 탭)
        if let tabBarController = self.tabBarController {
            tabBarController.selectedIndex = 1 // RoomList 탭
            navigationController?.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - 메모리 관리
    deinit {
        print("🗑️ RoomDetailViewController 해제")
    }
}
