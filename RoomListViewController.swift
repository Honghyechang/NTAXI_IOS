import UIKit
import CoreLocation
import CoreData

class RoomListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myBalance: UILabel!
    
    // 위치 관련
    var locationManager: CLLocationManager!
    var currentLocation: CLLocationCoordinate2D?
    
    // 사용자 정보
    var currentUserID: String!
    var currentUserUniversity: String!
    
    // 방 데이터
    var availableRooms: [Room] = []
    
    // 실시간 업데이트 타이머
    var refreshTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 🔥 전체 배경색을 연한 회색으로 설정
        view.backgroundColor = UIColor.systemGroupedBackground
        
        setupLocation()
        loadUserInfo()
        
        tableView.delegate = self
        tableView.dataSource = self
        setupTableViewDesign()
        // 🔥 테이블뷰 배경색도 동일하게 설정

        print("RoomListViewController 로드 완료")
    }
    // MARK: - 테이블뷰 디자인 설정
    private func setupTableViewDesign() {
           // 배경색 설정
           tableView.backgroundColor = UIColor.systemGroupedBackground
           
           // 🔥 모서리 둥글게 만들기 (단순하게)
           tableView.layer.cornerRadius = 12
           tableView.layer.masksToBounds = true
           
           // 🔥 분리된 스타일 설정
           tableView.separatorStyle = .none
           
           // 🔥 스크롤 인디케이터 스타일
           tableView.showsVerticalScrollIndicator = false
           
           print("테이블뷰 디자인 설정 완료")
       }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        updateUserBalance()
        loadAvailableRooms()
        startRealTimeUpdates() // 🔥 실시간 업데이트 시작
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopRealTimeUpdates() // 🔥 실시간 업데이트 중단
    }
    
    // MARK: - 위치 설정
    private func setupLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // iOS 버전 호환성을 위한 수정
        let authStatus = locationManager.authorizationStatus
        
        switch authStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            print("위치 서비스 시작")
        case .denied, .restricted:
            print("위치 권한이 거부되었습니다.")
            showLocationPermissionAlert()
        @unknown default:
            break
        }
    }
    
    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "위치 권한 필요",
            message: "N택시 앱이 정상적으로 작동하려면 위치 권한이 필요합니다. 설정에서 위치 서비스를 허용해주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "설정", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - 사용자 정보 로드
    private func loadUserInfo() {
        currentUserID = UserDefaults.standard.string(forKey: "currentUserID")
        currentUserUniversity = UserDefaults.standard.string(forKey: "currentUserUniversity")
        
        guard currentUserID != nil else {
            print("Error: currentUserID is nil")
            return
        }
    }
    
    private func updateUserBalance() {
        // Core Data에서 최신 잔액 조회
        if let currentUserID = currentUserID,
           let user = CoreDataManager.shared.getUser(userID: currentUserID) {
            let balance = user.balance
            myBalance.text = "잔액: \(NumberFormatter.localizedString(from: NSNumber(value: balance), number: .decimal))원"
            
            // UserDefaults도 업데이트
            UserDefaults.standard.set(balance, forKey: "currentUserBalance")
        }
    }
    
    // MARK: - 실시간 업데이트 관리
    private func startRealTimeUpdates() {
        // 기존 타이머가 있다면 중단
        stopRealTimeUpdates()
        
        // 5초마다 실시간 업데이트
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.performRealTimeUpdate()
        }
        
        print("실시간 업데이트 시작 (5초 간격)")
    }
    
    private func stopRealTimeUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("실시간 업데이트 중단")
    }
    
    private func performRealTimeUpdate() {
        print("🔄 실시간 업데이트 수행 중...")
        
        // 1. 사용자 잔액 업데이트
        updateUserBalance()
        
        // 2. 방 목록 새로고침 (다른 사용자가 입장해서 상태 변경될 수 있음)
        let previousRoomCount = availableRooms.count
        loadAvailableRooms()
        
        // 3. 방 개수가 변경되었으면 로그 출력
        if availableRooms.count != previousRoomCount {
            print("방 목록 변경: \(previousRoomCount) → \(availableRooms.count)개")
        }
        
        // 4. 위치 기반 거리 재계산 (내 위치가 변경되었을 수 있음)
        updateRoomDistances()
        
        // 5. UI 업데이트 (메인 스레드에서)
        DispatchQueue.main.async {
            self.tableView.reloadData()
            print("테이블뷰 새로고침 완료")
        }
    }
    
    // MARK: - 방 데이터 로드
    private func loadAvailableRooms() {
        guard let university = currentUserUniversity else { return }
        
        // 같은 학교의 모집 중인 방만 가져오기
        availableRooms = CoreDataManager.shared.getAvailableRooms(for: university)
        updateRoomDistances()
        tableView.reloadData()
        
        print("로드된 방 개수: \(availableRooms.count)")
    }
    
    private func updateRoomDistances() {
        guard let currentLocation = currentLocation else { return }
        
        for room in availableRooms {
            let roomLocation = CLLocation(latitude: room.startLatitude, longitude: room.startLongitude)
            let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let distance = userLocation.distance(from: roomLocation)
            
            // 1000m 이내의 방만 입장 가능으로 표시
            room.isAccessible = distance <= 1000
        }
    }
    
    // MARK: - 방 입장 처리
    private func handleRoomEntry(for room: Room, at indexPath: IndexPath) {
        guard let currentUserID = currentUserID else { return }
        
        // 거리 확인
        guard let currentLocation = currentLocation else {
            showAlert(title: "위치 오류", message: "위치 정보를 가져올 수 없습니다.")
            return
        }
        
        let roomLocation = CLLocation(latitude: room.startLatitude, longitude: room.startLongitude)
        let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let distance = userLocation.distance(from: roomLocation)
        
        if distance > 1000 {
            showAlert(title: "거리 초과", message: "이 방과 거리가 너무 멀어서 입장할 수 없습니다. (현재 거리: \(Int(distance))m)")
            return
        }
        
        // 잔액 확인
        if let user = CoreDataManager.shared.getUser(userID: currentUserID) {
            let requiredBalance = Int(Double(room.costPerPerson) * 1.2)
            
            if Int(user.balance) < requiredBalance {
                // 잔액 부족 알림 팝업 (HomeViewController와 동일)
                showBalanceAlert(
                    currentBalance: Int(user.balance),
                    estimatedCost: Int(room.costPerPerson),
                    requiredBalance: requiredBalance
                )
                return
            }
        }
        
        // 방 입장 처리
        let success = CoreDataManager.shared.joinRoom(roomID: room.roomID!, userID: currentUserID)
        
        if success {
            print("방 입장 성공: \(room.roomID!)")
            
            let alert = UIAlertController(title: "입장 완료", message: "방에 성공적으로 입장했습니다!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
                // RoomDetailViewController로 이동
                self.moveToRoomDetail(roomID: room.roomID!)
            })
            present(alert, animated: true)
        } else {
            showAlert(title: "입장 실패", message: "방 입장에 실패했습니다.")
        }
    }
    
    // MARK: - 알림 및 이동
    private func showBalanceAlert(currentBalance: Int, estimatedCost: Int, requiredBalance: Int) {
        let shortageAmount = requiredBalance - currentBalance
        
        let alert = UIAlertController(
            title: "💰 잔액이 부족합니다",
            message: nil,
            preferredStyle: .alert
        )
        
        let fullMessage = """
        방 입장을 위해 예상 비용의 20% 추가 금액이 필요합니다.
        
        현재 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: currentBalance), number: .decimal))원
        예상 비용: \(NumberFormatter.localizedString(from: NSNumber(value: estimatedCost), number: .decimal))원
        필요 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: requiredBalance), number: .decimal))원
        
        부족한 금액: \(NumberFormatter.localizedString(from: NSNumber(value: shortageAmount), number: .decimal))원
        """
        
        let attributedMessage = NSMutableAttributedString(string: fullMessage)
        
        // "20% 추가 금액" 부분을 빨간색으로 설정
        let redRange = (fullMessage as NSString).range(of: "20% 추가 금액")
        attributedMessage.addAttributes([
            .foregroundColor: UIColor.red,
            .font: UIFont.boldSystemFont(ofSize: 16)
        ], range: redRange)
        
        // "부족한 금액" 라인도 빨간색으로 강조
        let shortageRange = (fullMessage as NSString).range(of: "부족한 금액: \(NumberFormatter.localizedString(from: NSNumber(value: shortageAmount), number: .decimal))원")
        attributedMessage.addAttributes([
            .foregroundColor: UIColor.red,
            .font: UIFont.boldSystemFont(ofSize: 14)
        ], range: shortageRange)
        
        alert.setValue(attributedMessage, forKey: "attributedMessage")
        
        // 충전하러 가기 버튼
        let chargeAction = UIAlertAction(title: "충전하러 가기", style: .default) { _ in
            self.tabBarController?.selectedIndex = 2 // 설정 탭으로 이동
        }
        
        // 확인 버튼
        let confirmAction = UIAlertAction(title: "확인", style: .cancel)
        
        alert.addAction(chargeAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    
    
    private func moveToRoomDetail(roomID: String) {
        // TODO: RoomDetailViewController로 이동
        print("RoomDetailViewController로 이동 예정 - roomID: \(roomID)")
        
        // 스토리보드에서 RoomDetailViewController 가져오기 (구현 예정)
        /*
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let roomDetailVC = storyboard.instantiateViewController(withIdentifier: "RoomDetailViewController") as? RoomDetailViewController {
            roomDetailVC.roomID = roomID
            navigationController?.pushViewController(roomDetailVC, animated: true)
        }
        */
    }
    
    
    private func moveToCreateRoom() {
        print("CreateRoomViewController로 이동 시작")
        
        // 스토리보드에서 CreateRoomViewController 가져오기
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let createRoomVC = storyboard.instantiateViewController(withIdentifier: "CreateRoomViewController") as? CreateRoomViewController {
            // Navigation Controller를 통해 Push (뒤로가기 가능)
            navigationController?.pushViewController(createRoomVC, animated: true)
            print("CreateRoomViewController로 이동 완료")
        } else {
            print("Error: CreateRoomViewController를 찾을 수 없습니다!")
            
            // 에러 발생 시 사용자에게 알림
            let alert = UIAlertController(
                title: "오류",
                message: "방 만들기 화면을 불러올 수 없습니다.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
 
}

// MARK: - UITableViewDataSource
extension RoomListViewController {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableRooms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell", for: indexPath) as! CustomTableViewCell
        
        let room = availableRooms[indexPath.row]
        
        // 기본 방 정보 설정
        cell.startLabel?.text = room.startLocation
        cell.endLabel?.text = room.endLocation
        cell.costInfo?.text = "총 \(Int(room.estimatedCost))원 / 인당 \(Int(room.costPerPerson))원"
        cell.memberInfo?.text = "\(Int(room.currentMembers))/\(Int(room.maxMembers))명"
        cell.startAndEndLabel?.text = "\(room.startLocation ?? "") → \(room.endLocation ?? "")"
        
        // 🔥 고정 라벨들 설정
        cell.startfix?.text = "출발지"
        cell.endfix?.text = "목적지"
        cell.memberfix?.text = "인원"
        cell.costfix?.text = "예상 비용"
        
        // 거리 및 버튼 상태 설정
        if let currentLocation = currentLocation {
            let roomLocation = CLLocation(latitude: room.startLatitude, longitude: room.startLongitude)
            let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let distance = userLocation.distance(from: roomLocation)
            
            if distance > 1000 {
                // 거리 초과 - 버튼 비활성화
                cell.enterClick.isEnabled = false
                cell.setInactiveButtonStyle(title: "거리 초과", backgroundColor: .systemGray3)
                cell.errorMessage.text = "이 방과 거리가 너무 멀어서 입장할 수 없습니다. (현재 거리: \(Int(distance))m)"
                cell.errorMessage.isHidden = false
            } else {
                // 거리 조건 충족 - 버튼 활성화
                cell.enterClick.isEnabled = true
                cell.enterClick.setTitle("입장하기", for: .normal)
                cell.setActiveButtonStyle()
                cell.errorMessage.isHidden = true
            }
        } else {
            // 위치 정보 없음
            cell.enterClick.isEnabled = false
            cell.setInactiveButtonStyle(title: "위치 오류", backgroundColor: .systemGray3)
            cell.errorMessage.text = "위치 정보를 가져올 수 없습니다."
            cell.errorMessage.isHidden = false
        }
        
        // 🔥 기존 타겟 제거 후 새로 추가 (중복 방지)
        cell.enterClick.removeTarget(nil, action: nil, for: .allEvents)
        cell.enterClick.tag = indexPath.row
        cell.enterClick.addTarget(self, action: #selector(enterButtonTapped(_:)), for: .touchUpInside)
        
        return cell
    }
    
    @objc private func enterButtonTapped(_ sender: UIButton) {
        let roomIndex = sender.tag
        guard roomIndex < availableRooms.count else { return }
        
        let room = availableRooms[roomIndex]
        let indexPath = IndexPath(row: roomIndex, section: 0)
        
        handleRoomEntry(for: room, at: indexPath)
    }
}

// MARK: - UITableViewDelegate
extension RoomListViewController {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 253
    }
}

// MARK: - CLLocationManagerDelegate
extension RoomListViewController {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location.coordinate
        
        // 거리 계산 및 UI 업데이트
        updateRoomDistances()
        
        // 🔥 위치 변경 시 즉시 테이블뷰 새로고침 (버튼 상태 업데이트)
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        print("📍 위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("위치 권한 상태 변경: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("위치 권한 허용됨 - 위치 추적 시작")
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
