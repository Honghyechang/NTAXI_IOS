import UIKit
import MapKit
import CoreLocation

class CreateRoomViewController: UIViewController {
    
    @IBOutlet weak var pageChangeView: UIView! // 첫번째설정화면, 두번째 설정화면을 보여줄 뷰!!
    @IBOutlet weak var pageControl: UIPageControl! // 조건에 맞도록 조건에 맞으면 pagecontrol을 통해서 화면을 전환해주는거야!
    
    // MARK: - 공유 데이터 변수들
    var currentUserBalance: Int = 0
    var currentUserID: String!
    var currentUserUniversity: String!
    var selectedCoordinate: CLLocationCoordinate2D?
    var currentUserLocation: CLLocationCoordinate2D?
    var estimatedTotalCost: Int = 0
    var estimatedCostPerPerson: Int = 0
    var selectedMemberCount: Int = 2 // 기본값 2명
    var startLocationAddress: String = ""
    
    // 위치 관리자 및 지오코더
    var locationManager: CLLocationManager!
    let geocoder = CLGeocoder()
    
    // 자식 뷰 컨트롤러들
    var firstSetViewController: FirstSetViewController?
    var secondSetViewController: SecondSetViewController?
    var currentChildViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("🏠 CreateRoomViewController 로드 시작")
        
        setupUI()
        setupLocation()
        setupPageControl()
        loadUserInfo()
        
        // 첫 번째 페이지 표시
        showFirstPage()
        
        print("✅ CreateRoomViewController 로드 완료")
    }
    
    // MARK: - UI 초기 설정
    private func setupUI() {
        // 탭바 숨기기
        self.tabBarController?.tabBar.isHidden = true
        
        print("✅ UI 설정 완료")
    }
    
    // MARK: - 페이지 컨트롤 설정
    private func setupPageControl() {
        pageControl.numberOfPages = 2
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.systemGray4
        pageControl.currentPageIndicatorTintColor = UIColor.systemOrange
        
        // 🔥 페이지 컨트롤 직접 탭 비활성화 (조건 충족 시에만 이동)
        pageControl.isUserInteractionEnabled = false
        
        print("✅ 페이지 컨트롤 설정 완료 - 직접 탭 비활성화")
    }
    
    // MARK: - 위치 관리자 설정
    private func setupLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("위치 권한이 거부되었습니다.")
        @unknown default:
            break
        }
    }
    
    // MARK: - 사용자 정보 로드
    private func loadUserInfo() {
        currentUserID = UserDefaults.standard.string(forKey: "currentUserID")
        currentUserUniversity = UserDefaults.standard.string(forKey: "currentUserUniversity")
        
        // 사용자 잔액 가져오기
        if let user = CoreDataManager.shared.getUser(userID: currentUserID!) {
            currentUserBalance = Int(user.balance)
        }
        
        print("사용자 정보 로드 완료 - 학교: \(currentUserUniversity ?? ""), 잔액: \(currentUserBalance)원")
    }
    
    // MARK: - 페이지 전환 관리
    private func showFirstPage() {
        // 기존 자식 제거
        removeCurrentChild()
        
        // FirstSetViewController 생성 및 추가
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let firstVC = storyboard.instantiateViewController(withIdentifier: "FirstSetViewController") as? FirstSetViewController {
            firstVC.parentCreateRoom = self // 부모 참조 설정
            addChildViewController(firstVC, to: pageChangeView)
            firstSetViewController = firstVC
            
            pageControl.currentPage = 0
            print("📱 첫 번째 페이지 표시")
        } else {
            print("❌ FirstSetViewController를 찾을 수 없습니다")
        }
    }
    
    func showSecondPage() {
        // 기존 자식 제거
        removeCurrentChild()
        
        // SecondSetViewController 생성 및 추가
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let secondVC = storyboard.instantiateViewController(withIdentifier: "SecondSetViewController") as? SecondSetViewController {
            secondVC.parentCreateRoom = self // 부모 참조 설정
            addChildViewController(secondVC, to: pageChangeView)
            secondSetViewController = secondVC
            
            pageControl.currentPage = 1
            
            // 두 번째 페이지에 데이터 전달
            secondVC.receiveDataFromFirstPage(
                totalCost: estimatedTotalCost,
                memberCount: selectedMemberCount
            )
            
            print("📱 두 번째 페이지 표시")
        } else {
            print("❌ SecondSetViewController를 찾을 수 없습니다")
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
    
    // MARK: - FirstPage에서 호출할 메서드들
    func calculateTaxiCost(from startCoordinate: CLLocationCoordinate2D, to endCoordinate: CLLocationCoordinate2D) -> Int {
        let startLocation = CLLocation(latitude: startCoordinate.latitude, longitude: startCoordinate.longitude)
        let endLocation = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
        let distance = Int(startLocation.distance(from: endLocation))
        
        let estimatedDuration = Int(Double(distance) / 30000.0 * 3600.0)
        
        // 서울 택시 요금 계산
        let baseFare = 3800
        let baseDistance = 2000
        
        var totalFare = baseFare
        
        if distance > baseDistance {
            let extraDistance = distance - baseDistance
            let extraDistanceFare = (extraDistance / 132) * 100
            totalFare += extraDistanceFare
        }
        
        let timeAddition = Int(Double(estimatedDuration) * 0.1)
        totalFare += timeAddition
        
        totalFare = Int(Double(totalFare) * 1.15)
        
        print("💰 택시 요금 계산 완료 - 거리: \(distance)m, 총비용: \(totalFare)원")
        
        return totalFare
    }
    
    func handleFirstPageComplete(selectedCoordinate: CLLocationCoordinate2D, address: String) {
        // 첫 번째 페이지에서 받은 데이터 저장
        self.selectedCoordinate = selectedCoordinate
        self.startLocationAddress = address
        
        // 한성대학교 좌표 (목적지)
        let endCoordinate = CLLocationCoordinate2D(latitude: 37.58616528349631, longitude: 127.01280516488525)
        
        // 택시 요금 계산
        self.estimatedTotalCost = calculateTaxiCost(from: selectedCoordinate, to: endCoordinate)
        
        // 두 번째 페이지로 이동
        showSecondPage()
    }
    
    // MARK: - SecondPage에서 호출할 메서드들
    func handleMemberCountChange(_ memberCount: Int) {
        selectedMemberCount = memberCount
        estimatedCostPerPerson = estimatedTotalCost / memberCount
        print("🧑‍🤝‍🧑 인원 변경: \(memberCount)명, 인당 비용: \(estimatedCostPerPerson)원")
    }
    
    func checkBalanceCondition() -> (isValid: Bool, errorMessage: String?) {
        let requiredBalance = Int(Double(estimatedCostPerPerson) * 1.2)
        
        if currentUserBalance >= requiredBalance {
            return (true, nil)
        } else {
            let shortageAmount = requiredBalance - currentUserBalance
            let message = """
            방 만들기를 위해 예상 비용의 20% 추가 금액이 필요합니다.
            
            현재 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: currentUserBalance), number: .decimal))원
            필요 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: requiredBalance), number: .decimal))원
            부족한 금액: \(NumberFormatter.localizedString(from: NSNumber(value: shortageAmount), number: .decimal))원
            """
            return (false, message)
        }
    }
    
    func handleCreateRoom() {
        guard let startCoordinate = selectedCoordinate else {
            print("❌ 출발지가 선택되지 않음")
            return
        }
        
        // 방 생성 데이터 준비
        let roomID = "room_\(UUID().uuidString.prefix(8))"
        let ownerID = currentUserID!
        let startLocation = startLocationAddress
        let endLocation = currentUserUniversity!
        let endCoordinate = CLLocationCoordinate2D(latitude: 37.58616528349631, longitude: 127.01280516488525)
        
        print("방 생성 정보:")
        print("  - roomID: \(roomID)")
        print("  - 방장: \(ownerID)")
        print("  - 출발지: \(startLocation)")
        print("  - 목적지: \(endLocation)")
        print("  - 최대인원: \(selectedMemberCount)명")
        print("  - 예상비용: \(estimatedTotalCost)원 (인당 \(estimatedCostPerPerson)원)")
        
        // 🔥 Core Data에 방 생성 (Room + RoomMember 동시 생성)
        let success = CoreDataManager.shared.createRoom(
            roomID: roomID,
            ownerID: ownerID,
            startLocation: startLocation,
            startLatitude: startCoordinate.latitude,
            startLongitude: startCoordinate.longitude,
            endLocation: endLocation,
            endLatitude: endCoordinate.latitude,
            endLongitude: endCoordinate.longitude,
            maxMembers: selectedMemberCount,
            estimatedCost: estimatedTotalCost,
            costPerPerson: estimatedCostPerPerson
        )
        
        if success {
            print("✅ 방 생성 성공: \(roomID)")
            
            // 🔥 방 생성 성공 시 즉시 해당 방으로 이동
            navigateToRoomDetail(roomID: roomID)
            
        } else {
            print("❌ 방 생성 실패")
            
            let alert = UIAlertController(
                title: "오류",
                message: "방 만들기에 실패했습니다. 다시 시도해주세요.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
    
    // 🔥 새로 추가: RoomDetail로 이동하는 메서드
    private func navigateToRoomDetail(roomID: String) {
        print("🚪 방 상세 화면으로 이동: \(roomID)")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let roomDetailVC = storyboard.instantiateViewController(withIdentifier: "RoomDetailViewController") as? RoomDetailViewController {
            
            // 🔥 roomID 데이터 전달
            roomDetailVC.receivedRoomID = roomID
            
            // 네비게이션으로 이동 (뒤로 가기 가능)
            navigationController?.pushViewController(roomDetailVC, animated: true)
            
            print("✅ RoomDetailViewController로 이동 완료 - roomID: \(roomID)")
        } else {
            print("❌ RoomDetailViewController를 찾을 수 없습니다")
            
            // 스토리보드에서 찾을 수 없는 경우 일반 알림으로 대체
            let alert = UIAlertController(
                title: "🎉 방 만들기 완료",
                message: "새로운 방이 성공적으로 만들어졌습니다!\n방 ID: \(roomID)",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                print("방 만들기 완료 - 이전 화면으로 돌아가기")
                self.navigationController?.popViewController(animated: true)
            })
            
            present(alert, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate (🔥 클래스 외부로 이동)
extension CreateRoomViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentUserLocation = location.coordinate
            print("📍 현재 위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // 첫 번째 페이지에 위치 정보 전달
            firstSetViewController?.updateCurrentLocation(location.coordinate)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("위치 권한이 거부되었습니다.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
