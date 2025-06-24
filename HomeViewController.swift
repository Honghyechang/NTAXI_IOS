import UIKit
import MapKit
import CoreLocation
import CoreData

class HomeViewController: UIViewController {

    @IBOutlet weak var balanceBackground: UIView! // 금액배경 컨테이너
    @IBOutlet weak var myBalance: UILabel! // 이용자 계좌 금액
    
    @IBOutlet weak var mapView: MKMapView! // 지도 보여주는 부분
    
    // 각각의 마커 컨테이너 즉, 이미지를 채워서 원형으로 보여주기
    @IBOutlet weak var taxiMarker: UIView!
    @IBOutlet weak var mylocationMarker: UIView!
    @IBOutlet weak var schoolMarker: UIView!
    
    // 고정 라벨들 (항상 표시)
    @IBOutlet weak var startfix: UILabel!
    @IBOutlet weak var costfix: UILabel!
    @IBOutlet weak var endfix: UILabel!
    @IBOutlet weak var memberfix: UILabel!
    
    @IBOutlet weak var startAndEndLabel: UILabel! // 한성대입구역->한성대학교 출발지와 도착지 보여주는 라벨
    
    // 변하는 값 라벨들
    @IBOutlet weak var startLabel: UILabel! // 시작위치라벨
    @IBOutlet weak var endLabel: UILabel! // 도착위치라벨
    @IBOutlet weak var memberInfo: UILabel! // 현재 방맴버정보 2/4명 과같이
    @IBOutlet weak var costInfo: UILabel! // 비용정보 총4000/4=인당 1000원
    @IBOutlet weak var errorMessage: UILabel! // 에러메시지
    
    @IBOutlet weak var infoContainer: UIView!
    // 하단 팝업 관련
    @IBOutlet weak var bottomPopupView: UIView!
    @IBOutlet weak var enterRoomButton: UIButton!
    
    // 위치 관련
    var locationManager: CLLocationManager!
    var currentLocation: CLLocationCoordinate2D?
    var currentUserID: String!
    var currentUserUniversity: String!
    
    // 🔥 새로 추가: 위치 업데이트 타이머
    var locationUpdateTimer: Timer?
    
    // 방 데이터
    var availableRooms: [Room] = []
    var selectedRoom: Room?
    
    // 한성대학교 좌표 (정확한 좌표로 수정)
    let hansungUniversityLocation = CLLocationCoordinate2D(latitude: 37.58616528349631, longitude: 127.01280516488525)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupLocation()
        setupMapView()
        loadUserInfo()
        hideBottomPopup() // 초기에는 팝업 숨김
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 🔧 범례 마커들을 완전한 원형으로 만들기
        let markers = [mylocationMarker, taxiMarker, schoolMarker]
        
        for marker in markers {
            guard let marker = marker else { continue }
            
            // 정확한 원형을 위해 너비와 높이 중 작은 값을 사용
            let size = min(marker.frame.width, marker.frame.height)
            marker.layer.cornerRadius = size / 2
            
            // 완전한 정사각형으로 만들기 (필요한 경우)
            if marker.frame.width != marker.frame.height {
                marker.layer.masksToBounds = true
            }
        }
        
        // 초기에 팝업을 화면 아래로 완전히 숨김
        if selectedRoom == nil {
            bottomPopupView.transform = CGAffineTransform(translationX: 0, y: bottomPopupView.frame.height)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUserBalance()
        loadAvailableRooms()
        checkIfUserInRoom()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        locationManager.stopUpdatingLocation() // 🔥 추가
        stopPeriodicLocationUpdates() // 🔥 이 줄은 유지 (타이머 정리용)
    }
    
    deinit {
        stopPeriodicLocationUpdates()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // 범례 마커들을 원형으로 만들기
        setupLegendMarkers()
        
        // 하단 팝업 스타일링
        bottomPopupView.layer.cornerRadius = 16
        bottomPopupView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomPopupView.layer.shadowColor = UIColor.black.cgColor
        bottomPopupView.layer.shadowOpacity = 0.1
        bottomPopupView.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomPopupView.layer.shadowRadius = 8
        
        // 입장 버튼 스타일링
        enterRoomButton.layer.cornerRadius = 8
        enterRoomButton.backgroundColor = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0) // #FF9500
        
        // 고정 라벨들 설정 (항상 표시)
        startfix.text = "출발지"
        endfix.text = "목적지"
        memberfix.text = "인원"
        costfix.text = "예상 비용"
        
        // 초기 팝업 라벨들 초기화
        clearPopupLabels()
    }
    
    // 팝업 라벨 초기화 함수
    private func clearPopupLabels() {
        startAndEndLabel.text = ""
        startLabel.text = ""
        endLabel.text = ""
        memberInfo.text = ""
        costInfo.text = ""
        errorMessage.text = ""
        errorMessage.isHidden = true
    }
    
    private func setupLegendMarkers() {
        // 범례 마커들 원형 + 이미지 설정
        let markers = [
            (mylocationMarker, "mylocation"),
            (taxiMarker, "taxi"),
            (schoolMarker, "school")
        ]
        
        for (marker, imageName) in markers {
            guard let marker = marker else { continue }
            
            marker.clipsToBounds = true
            
            // 배경색을 이미지 색상과 동일하게 설정
            switch imageName {
            case "mylocation":
                marker.backgroundColor = UIColor.systemBlue
            case "taxi":
                marker.backgroundColor = UIColor.systemOrange
            case "school":
                marker.backgroundColor = UIColor.systemRed
            default:
                break
            }
            
            // 이미지뷰를 마커 전체 크기로 설정 (가득 채움)
            let imageView = UIImageView(image: UIImage(named: imageName))
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.tintColor = .white // 이미지를 흰색으로 표시
            imageView.tag = 100 // 나중에 찾기 위한 태그
            marker.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: marker.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: marker.centerYAnchor),
                imageView.widthAnchor.constraint(equalTo: marker.widthAnchor, multiplier: 0.5),
                imageView.heightAnchor.constraint(equalTo: marker.heightAnchor, multiplier: 0.5)
            ])
        }
    }
    
    // MARK: - 위치 설정
    private func setupLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // 위치 권한 상태 확인
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            locationManager.distanceFilter = 10 // 🔥 추가: 10m마다 업데이트
            print("위치 서비스 시작")
        case .denied, .restricted:
            print("위치 권한이 거부되었습니다.")
            showLocationPermissionAlert()
        @unknown default:
            break
        }
    }
    
  
    
    // 🔥 새로 추가: 주기적 위치 업데이트 중단
    private func stopPeriodicLocationUpdates() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
        print("⏹️ 주기적 위치 업데이트 타이머 중단")
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
    
    // MARK: - 맵뷰 설정
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = false // 🔥 수정: 기본 사용자 위치 표시 끄기 (커스텀 마커 사용)
        mapView.userTrackingMode = .none
        
        // 지도 탭 제스처 추가 (팝업 숨기기용) - 더 강력한 방식
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        tapGesture.delegate = self
        mapView.addGestureRecognizer(tapGesture)
        
        // 한성대학교 중심으로 지도 표시
        let region = MKCoordinateRegion(
            center: hansungUniversityLocation,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        mapView.setRegion(region, animated: false)
        
        // 한성대학교 마커 추가
        addSchoolAnnotation()
    }

    // 지도 탭 액션 함수 - 수정된 버전
    @objc private func mapTapped(_ gesture: UITapGestureRecognizer) {
        // 팝업이 올라와 있을 때만 숨기기 처리
        if selectedRoom != nil {
            print("지도 탭 감지 - 팝업 숨기기")
            hideBottomPopup()
        }
    }
    
    private func addSchoolAnnotation() {
        let schoolAnnotation = MKPointAnnotation()
        schoolAnnotation.coordinate = hansungUniversityLocation
        schoolAnnotation.title = "한성대학교"
        schoolAnnotation.subtitle = "목적지"
        mapView.addAnnotation(schoolAnnotation)
    }
    
    // 🔥 새로 추가: 내 위치 마커 업데이트 함수
    private func updateMyLocationMarker(location: CLLocationCoordinate2D) {
        // 기존 사용자 위치 마커 제거 (MKUserLocation과 커스텀 마커 모두)
        let userAnnotations = mapView.annotations.filter { annotation in
            return annotation is MKUserLocation || annotation.title == "내 위치"
        }
        mapView.removeAnnotations(userAnnotations)
        
        // 새로운 사용자 위치 마커 추가
        let userAnnotation = MKPointAnnotation()
        userAnnotation.coordinate = location
        userAnnotation.title = "내 위치"
        userAnnotation.subtitle = "현재 위치"
        mapView.addAnnotation(userAnnotation)
        
        print("📍 내 위치 마커 업데이트: 위도 \(location.latitude), 경도 \(location.longitude)")
    }
    
    // 이미지 리사이즈 헬퍼 함수
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
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
    
    // MARK: - 방 데이터 로드
    private func loadAvailableRooms() {
        guard let university = currentUserUniversity else { return }
        
        // 같은 학교의 모집 중인 방만 가져오기
        availableRooms = CoreDataManager.shared.getAvailableRooms(for: university)
        updateRoomMarkers()
    }
    
    private func updateRoomMarkers() {
        // 기존 방 마커들 제거 (학교 마커와 내 위치 마커 제외)
        let roomAnnotations = mapView.annotations.filter { annotation in
            return !(annotation.title == "한성대학교") && !(annotation.title == "내 위치")
        }
        mapView.removeAnnotations(roomAnnotations)
        
        // 새로운 방 마커들 추가
        for room in availableRooms {
            let annotation = RoomAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: room.startLatitude,
                longitude: room.startLongitude
            )
            annotation.title = room.startLocation
            annotation.subtitle = "\(room.currentMembers)/\(room.maxMembers)명"
            annotation.room = room
            
            mapView.addAnnotation(annotation)
        }
        
        // 각 방과의 거리 계산 및 UI 업데이트
        updateRoomDistances()
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
        
        // 선택된 방이 있다면 거리 재확인
        if let selectedRoom = selectedRoom {
            checkRoomAccessibility(for: selectedRoom)
        }
    }
    
    // 현재 위치가 특정 방에 참여 중인지 확인하는 함수
    private func checkIfUserInRoom() {
        guard let currentUserID = currentUserID else { return }
        
        // 사용자가 현재 참여 중인 방이 있는지 확인
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "userID == %@", currentUserID)
        
        do {
            let context = CoreDataManager.shared.context
            let memberships = try context.fetch(memberRequest)
            
            if let membership = memberships.first,
               let roomID = membership.roomID,
               let room = CoreDataManager.shared.getRoom(roomID: roomID) {
                
                if room.status == "완료" {
                    // 사용자가 "완료" 상태의 방에 참여 중이면 위치 업데이트 시작
                    print("사용자가 완료 상태의 방에 참여 중 - 위치 업데이트 필요: \(roomID)")
                }
            }
        } catch {
            print("Error checking user room membership: \(error)")
        }
    }

    private func checkRoomAccessibility(for room: Room) {
        guard let currentLocation = currentLocation else {
            showError("위치 정보를 가져올 수 없습니다.")
            setEnterButtonState(enabled: false, title: "위치 오류", color: .gray)
            return
        }
        
        let roomLocation = CLLocation(latitude: room.startLatitude, longitude: room.startLongitude)
        let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let distance = userLocation.distance(from: roomLocation)
        
        // 거리 기준을 1000m로 설정
        if distance > 1000 {
            showError("이 방과 거리가 너무 멀어서 입장할 수 없습니다. (현재 거리: \(Int(distance))m)")
            setEnterButtonState(enabled: false, title: "거리 초과", color: .gray)
        } else if room.status == "대기중" {
            showError("이 방은 정원이 가득 차서 입장할 수 없습니다.")
            setEnterButtonState(enabled: false, title: "정원 마감", color: .red)
        } else if room.status == "완료" {
            showError("이 방은 이미 출발했습니다.")
            setEnterButtonState(enabled: false, title: "출발 완료", color: .gray)
        } else if room.status == "모집중" {
            hideError()
            setEnterButtonState(enabled: true, title: "입장하기", color: UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0))
        } else {
            showError("알 수 없는 방 상태입니다.")
            setEnterButtonState(enabled: false, title: "입장 불가", color: .gray)
        }
    }

    // 버튼 상태 설정 헬퍼 함수
    private func setEnterButtonState(enabled: Bool, title: String, color: UIColor) {
        enterRoomButton.isEnabled = enabled
        enterRoomButton.setTitle(title, for: .normal)
        enterRoomButton.backgroundColor = color
    }

    // MARK: - 팝업 관리
    private func showBottomPopup(for room: Room) {
        selectedRoom = room
        
        print("팝업 표시 시작: \(room.startLocation ?? "")")
        // 고정 라벨들과 버튼 보이기
        startfix.isHidden = false
        endfix.isHidden = false
        memberfix.isHidden = false
        costfix.isHidden = false
        enterRoomButton.isHidden = false
        infoContainer.isHidden = false
        
        // 방 정보 표시 (변하는 값들만)
        startAndEndLabel.text = "\(room.startLocation ?? "") → \(room.endLocation ?? "")"
        startLabel.text = room.startLocation ?? ""
        endLabel.text = room.endLocation ?? ""
        memberInfo.text = "\(Int(room.currentMembers))/\(Int(room.maxMembers))명"
        costInfo.text = "총 \(Int(room.estimatedCost))원 / 인당 \(Int(room.costPerPerson))원"
        
        // 거리 확인
        checkRoomAccessibility(for: room)
        
        // 팝업 애니메이션
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.bottomPopupView.transform = .identity
        } completion: { _ in
            print("팝업 표시 완료")
        }
    }
    
    private func hideBottomPopup() {
        print("팝업 숨기기 시작")
        selectedRoom = nil
        // 고정 라벨들과 버튼 숨기기
        startfix.isHidden = true
        endfix.isHidden = true
        memberfix.isHidden = true
        costfix.isHidden = true
        enterRoomButton.isHidden = true
        infoContainer.isHidden = true
        
        // 팝업 숨길 때 변하는 값들 초기화
        clearPopupLabels()
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.bottomPopupView.transform = CGAffineTransform(translationX: 0, y: self.bottomPopupView.frame.height)
        } completion: { _ in
            print("팝업 숨기기 완료")
        }
    }
    
    // MARK: - 에러 메시지
    private func showError(_ message: String) {
        errorMessage.text = message
        errorMessage.textColor = .red
        errorMessage.isHidden = false
    }
    
    private func hideError() {
        errorMessage.isHidden = true
        errorMessage.text = ""
    }
    
    // MARK: - 방 입장
    @IBAction func enterClick(_ sender: UIButton) {
        guard let room = selectedRoom else { return }
        guard let currentUserID = currentUserID else { return }
        
        // 버튼이 비활성화되어 있으면 입장 시도 차단
        if !sender.isEnabled {
            print("버튼이 비활성화된 상태에서 입장 시도 차단")
            return
        }
        
        // 최종 상태 재확인
        guard room.status == "모집중" else {
            showError("이 방은 더 이상 입장할 수 없습니다.")
            return
        }
        
        // 거리 재확인
        guard let currentLocation = currentLocation else {
            showError("위치 정보를 가져올 수 없습니다.")
            return
        }
        
        let roomLocation = CLLocation(latitude: room.startLatitude, longitude: room.startLongitude)
        let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let distance = userLocation.distance(from: roomLocation)
        
        if distance > 1000 {
            showError("이 방과 거리가 너무 멀어서 입장할 수 없습니다.")
            return
        }
        
        // 잔액 확인 (버튼이 활성화되어 있어도 잔액 부족 시 팝업으로 알림)
        if let user = CoreDataManager.shared.getUser(userID: currentUserID) {
            let requiredBalance = Int(Double(room.costPerPerson) * 1.2)
            
            if Int(user.balance) < requiredBalance {
                // 잔액 부족 알림 팝업
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
                self.hideBottomPopup()
                self.loadAvailableRooms() // 방 목록 새로고침
            })
            present(alert, animated: true)
        } else {
            showError("방 입장에 실패했습니다.")
        }
    }
    
    // 20% 추가 금액을 빨간색으로 강조하는 버전
    private func showBalanceAlert(currentBalance: Int, estimatedCost: Int, requiredBalance: Int) {
        let shortageAmount = requiredBalance - currentBalance
        
        let alert = UIAlertController(
            title: "💰 잔액이 부족합니다",
            message: nil,
            preferredStyle: .alert
        )
        
        // NSAttributedString으로 20% 부분을 빨간색으로 강조
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
            self.tabBarController?.selectedIndex = 2
        }
        
        // 확인 버튼
        let confirmAction = UIAlertAction(title: "확인", style: .cancel)
        
        alert.addAction(chargeAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location.coordinate
        
        // 🔥 핵심: 내 위치 마커 업데이트
        updateMyLocationMarker(location: location.coordinate)
        
        // 🔥 핵심: 위치 정보 프린트 출력
        print("🌍 실시간 위치 업데이트!")
        print("📍 위도(latitude): \(location.coordinate.latitude)")
        print("📍 경도(longitude): \(location.coordinate.longitude)")
        print("⏰ 업데이트 시간: \(Date())")
        print("----------------------------------------")
        
        // 방과의 거리 계산 및 UI 업데이트
        updateRoomDistances()
        
        // 사용자가 "완료" 상태 방에 참여 중이면 위치를 DB에 업데이트
        if let currentUserID = currentUserID {
            let success = CoreDataManager.shared.updateUserLocation(
                userID: currentUserID,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            
            if success {
                print("💾 사용자 위치 DB 업데이트 완료")
            }
        }
    }
    
    // 단발성 위치 요청 실패 처리
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ 위치 업데이트 실패: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("🔐 위치 권한 상태 변경: \(status.rawValue)")
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 허용됨 - 위치 추적 시작")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("❌ 위치 권한이 거부되었습니다.")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}

// MARK: - MKMapViewDelegate
extension HomeViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 🔥 커스텀 내 위치 마커 (MKPointAnnotation)
        if let pointAnnotation = annotation as? MKPointAnnotation,
           pointAnnotation.title == "내 위치" {
            let identifier = "MyLocationAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                // mylocation 이미지를 사용해서 커스텀 사용자 위치 표시
                if let originalImage = UIImage(named: "mylocation") {
                    let newSize = CGSize(width: 20, height: 20)
                    let customImage = resizeImage(image: originalImage, targetSize: newSize)
                    
                    // 원형 배경 추가
                    let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                    circleView.backgroundColor = UIColor.systemBlue
                    circleView.layer.cornerRadius = 12
                    circleView.layer.borderWidth = 2
                    circleView.layer.borderColor = UIColor.white.cgColor
                    
                    // 이미지뷰를 원형 배경에 추가
                    let imageView = UIImageView(image: customImage)
                    imageView.frame = CGRect(x: 2, y: 2, width: 20, height: 20)
                    imageView.tintColor = .white
                    circleView.addSubview(imageView)
                    
                    // UIView를 UIImage로 변환
                    UIGraphicsBeginImageContextWithOptions(circleView.bounds.size, false, 0)
                    circleView.layer.render(in: UIGraphicsGetCurrentContext()!)
                    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    annotationView?.image = finalImage
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        // 기존 MKUserLocation 처리 (iOS 기본 사용자 위치) - 숨김 처리
        if annotation is MKUserLocation {
            return nil // 기본 사용자 위치 마커 숨김
        }
        
        // 학교 마커
        if annotation.title == "한성대학교" {
            let identifier = "SchoolAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // 이미지 크기 조절
                if let originalImage = UIImage(named: "school") {
                    let newSize = CGSize(width: 30, height: 30)
                    annotationView?.image = resizeImage(image: originalImage, targetSize: newSize)
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        // 방 마커
        if let roomAnnotation = annotation as? RoomAnnotation {
            let identifier = "RoomAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                
                // 이미지 크기 조절
                if let originalImage = UIImage(named: "taxi") {
                    let newSize = CGSize(width: 25, height: 25)
                    annotationView?.image = resizeImage(image: originalImage, targetSize: newSize)
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // 방 마커 선택 시 하단 팝업 표시
        if let roomAnnotation = view.annotation as? RoomAnnotation,
           let room = roomAnnotation.room {
            print("마커 선택됨: \(room.startLocation ?? "")")
            showBottomPopup(for: room)
        }
        
        // 마커 선택 해제 (지도가 마커 중심으로 이동하지 않도록)
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension HomeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 항상 제스처를 받도록 설정 (팝업이 있을 때 지도 탭으로 숨기기)
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 지도의 다른 제스처와 동시에 인식되도록 허용
        return true
    }
}

// MARK: - Custom Annotation
class RoomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var subtitle: String?
    var room: Room?
}
