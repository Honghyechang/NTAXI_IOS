import UIKit
import MapKit
import CoreLocation

class StepTwoController: UIViewController {
    
    @IBOutlet weak var realTimeCheckView: UIView!
    @IBOutlet weak var markerInfoView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var notifyLabel: UILabel!
    
    // 부모 뷰 컨트롤러 참조
    weak var parentRoomDetail: RoomDetailViewController?
    
    // 위치 관련
    var locationManager: CLLocationManager!
    var currentRoom: Room?
    var roomMembers: [(user: User, member: RoomMember)] = []
    
    // 타이머 및 시뮬레이션
    var locationUpdateTimer: Timer?
    var memberLocationUpdateTimer: Timer?
    
    // UI 컴포넌트들
    var memberStatusCards: [UIView] = []
    var memberLegendItems: [UIView] = []
    var memberColors: [String: UIColor] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 StepTwoController 로드 시작")
        
        setupUI()
        setupLocation()
        setupMapView()
        loadRoomData()
        startLocationSimulation()
        
        print("✅ StepTwoController 로드 완료")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 알림 라벨 설정
        setupNotifyLabel()
        
        // 실시간 체크 뷰 설정
        setupRealTimeCheckView()
        
        // 범례 뷰 설정
        setupMarkerInfoView()
        
        // 택시 호출 버튼 설정
        setupCallButton()
        
        print("✅ Step 2 UI 설정 완료")
    }
    
    // MARK: - 알림 라벨 설정
    private func setupNotifyLabel() {
        guard let room = parentRoomDetail?.currentRoom else { return }
        
        let startLocation = room.startLocation ?? "출발지"
        let endLocation = room.endLocation ?? "목적지"
        
        // 🎨 이쁜 메시지 구성 (개행 처리)
        let message = "📍 \(startLocation)\n↓\n\(endLocation)\n\n🚶‍♂️ 출발지 100m 이내로 모여주세요!"
        
        notifyLabel.text = message
        notifyLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        notifyLabel.textColor = UIColor.label
        notifyLabel.textAlignment = .center
        notifyLabel.numberOfLines = 0 // 🔥 여러 줄 표시
        
        // 🎨 배경 스타일링
        notifyLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        notifyLabel.layer.cornerRadius = 12
        notifyLabel.layer.masksToBounds = true
        notifyLabel.layer.borderWidth = 1
        notifyLabel.layer.borderColor = UIColor.systemOrange.cgColor
    }
    
    // MARK: - 실시간 체크 뷰 설정
    private func setupRealTimeCheckView() {
        realTimeCheckView.layer.cornerRadius = 12
        realTimeCheckView.backgroundColor = UIColor.systemBackground
        realTimeCheckView.layer.borderWidth = 1
        realTimeCheckView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // 제목 라벨 추가
        let titleLabel = UILabel()
        titleLabel.text = "📍 실시간 도착 현황"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        realTimeCheckView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: realTimeCheckView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: realTimeCheckView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: realTimeCheckView.trailingAnchor, constant: -16)
        ])
        
        // 스크롤 가능한 컨테이너 추가
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        realTimeCheckView.addSubview(scrollView)
        
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: realTimeCheckView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: realTimeCheckView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: realTimeCheckView.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // 멤버 상태 카드들을 contentView에 추가할 예정
        contentView.tag = 1000 // 나중에 찾기 위한 태그
    }
    
    // MARK: - 범례 뷰 설정
    private func setupMarkerInfoView() {
        markerInfoView.layer.cornerRadius = 12
        markerInfoView.backgroundColor = UIColor.systemBackground
        markerInfoView.layer.borderWidth = 1
        markerInfoView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // 제목 라벨 추가
        let titleLabel = UILabel()
        titleLabel.text = "🏷️ 멤버 마커 범례"
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        markerInfoView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: markerInfoView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: markerInfoView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: markerInfoView.trailingAnchor, constant: -8)
        ])
        
        // 범례 아이템들을 위한 스택뷰
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        markerInfoView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: markerInfoView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: markerInfoView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: markerInfoView.bottomAnchor, constant: -8)
        ])
        
        stackView.tag = 2000 // 나중에 찾기 위한 태그
    }
    
    // MARK: - 택시 호출 버튼 설정
    private func setupCallButton() {
        callButton.layer.cornerRadius = 12
        callButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        // 초기 비활성화 상태
        callButton.isEnabled = false
        callButton.backgroundColor = UIColor.systemGray3
        callButton.setTitle("모든 멤버를 기다리는 중...", for: .normal)
        callButton.setTitleColor(.white, for: .normal)
        
        // 그림자 효과
        callButton.layer.shadowColor = UIColor.black.cgColor
        callButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        callButton.layer.shadowOpacity = 0.1
        callButton.layer.shadowRadius = 4
    }
    
    // MARK: - 위치 관리자 설정
    private func setupLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // 5m마다 업데이트
        
        // 위치 권한 요청 및 시작
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            print("위치 권한이 없습니다")
        }
    }
    
    // MARK: - 지도 뷰 설정
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = false // 커스텀 마커 사용
        
        guard let room = parentRoomDetail?.currentRoom else { return }
        
        // 출발지 중심으로 지도 설정 (확대)
        let startLocation = CLLocationCoordinate2D(
            latitude: room.startLatitude,
            longitude: room.startLongitude
        )
        
        let region = MKCoordinateRegion(
            center: startLocation,
            latitudinalMeters: 300, // 300m 반경 (100m 원이 잘 보이도록)
            longitudinalMeters: 300
        )
        mapView.setRegion(region, animated: false)
        
        // 100m 원형 오버레이 추가
        let circle = MKCircle(center: startLocation, radius: 100.0)
        mapView.addOverlay(circle)
        
        // 출발지 마커 추가
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = startLocation
        startAnnotation.title = "출발지"
        startAnnotation.subtitle = room.startLocation
        mapView.addAnnotation(startAnnotation)
        
        print("✅ 지도 설정 완료 - 출발지: \(room.startLocation ?? "")")
    }
    
    // MARK: - 방 데이터 로드
    private func loadRoomData() {
        guard let room = parentRoomDetail?.currentRoom,
              let roomID = room.roomID else { return }
        
        currentRoom = room
        
        // 방 멤버들 로드
        roomMembers = CoreDataManager.shared.getRoomMembersWithLocation(roomID: roomID)
        
        // 🔥 초기 위치를 출발지 1000m 이내로 설정
        initializeMemberPositions()
        
        // 멤버별 색상 할당
        assignMemberColors()
        
        // UI 업데이트
        updateMemberStatusCards()
        updateMarkerLegend()
        updateMemberMarkers()
        
        print("✅ 방 데이터 로드 완료 - 멤버 수: \(roomMembers.count)")
    }
    
    // MARK: - 🔥 멤버 초기 위치 설정 (출발지 1000m 이내)
    private func initializeMemberPositions() {
        guard let room = currentRoom else { return }
        
        let startLocation = CLLocationCoordinate2D(
            latitude: room.startLatitude,
            longitude: room.startLongitude
        )
        
        print("🎯 출발지 좌표: (\(startLocation.latitude), \(startLocation.longitude))")
        
        for memberData in roomMembers {
            let user = memberData.user
            guard let userID = user.userID else { continue }
            
            // 🔥 출발지 중심으로 500-1000m 반경 내 랜덤 위치 생성
            let randomDistance = Double.random(in: 500...1000) // 500-1000m
            let randomAngle = Double.random(in: 0...(2 * Double.pi)) // 0-360도
            
            // 위도/경도 오프셋 계산 (대략적인 계산)
            let latOffset = (randomDistance * cos(randomAngle)) / 111000.0 // 1도 ≈ 111km
            let lngOffset = (randomDistance * sin(randomAngle)) / (111000.0 * cos(startLocation.latitude * Double.pi / 180.0))
            
            let newLatitude = startLocation.latitude + latOffset
            let newLongitude = startLocation.longitude + lngOffset
            
            // 위치 업데이트
            let success = CoreDataManager.shared.updateUserLocation(
                userID: userID,
                latitude: newLatitude,
                longitude: newLongitude
            )
            
            if success {
                // 메모리에서도 업데이트
                user.currentLatitude = newLatitude
                user.currentLongitude = newLongitude
                
                // 실제 거리 계산으로 검증
                let actualLocation = CLLocation(latitude: newLatitude, longitude: newLongitude)
                let startCLLocation = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
                let actualDistance = actualLocation.distance(from: startCLLocation)
                
                print("✅ \(userID) 초기 위치 설정: \(Int(actualDistance))m (목표: \(Int(randomDistance))m)")
            } else {
                print("❌ \(userID) 위치 설정 실패")
            }
        }
    }
    
    // MARK: - 멤버별 색상 할당
    private func assignMemberColors() {
        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemPink, .systemTeal, .systemIndigo
        ]
        
        memberColors.removeAll()
        
        for (index, memberData) in roomMembers.enumerated() {
            let userID = memberData.user.userID ?? "Unknown"
            let color = colors[index % colors.count]
            memberColors[userID] = color
        }
    }
    
    // MARK: - 멤버 상태 카드 업데이트
    private func updateMemberStatusCards() {
        guard let contentView = realTimeCheckView.viewWithTag(1000) else { return }
        
        // 기존 카드들 제거
        memberStatusCards.forEach { $0.removeFromSuperview() }
        memberStatusCards.removeAll()
        
        // 새로운 카드들 추가
        for (index, memberData) in roomMembers.enumerated() {
            let card = createMemberStatusCard(memberData: memberData, index: index)
            contentView.addSubview(card)
            memberStatusCards.append(card)
        }
        
        // Auto Layout 설정
        layoutMemberStatusCards(in: contentView)
    }
    
    // MARK: - 개별 멤버 상태 카드 생성
    private func createMemberStatusCard(memberData: (user: User, member: RoomMember), index: Int) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 6 // 🔥 라운드 축소 (8 → 6)
        card.backgroundColor = UIColor.systemGray6
        card.layer.borderWidth = 2
        
        let userName = memberData.user.name ?? memberData.user.userID ?? "Unknown"
        let userID = memberData.user.userID ?? "Unknown"
        let isCurrentUser = (userID == parentRoomDetail?.currentUserID)
        
        // 색상 설정
        let userColor = memberColors[userID] ?? UIColor.systemGray
        card.layer.borderColor = userColor.cgColor
        
        // 프로필 아이콘 (크기 축소)
        let profileView = UIView()
        profileView.backgroundColor = userColor
        profileView.layer.cornerRadius = 10 // 🔥 크기 축소 (12 → 10)
        profileView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconLabel = UILabel()
        iconLabel.text = isCurrentUser ? "🙋‍♂️" : "👤"
        iconLabel.font = UIFont.systemFont(ofSize: 10) // 🔥 폰트 축소 (12 → 10)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        profileView.addSubview(iconLabel)
        
        // 이름 라벨 (축소)
        let nameLabel = UILabel()
        nameLabel.text = isCurrentUser ? "\(userName)(나)" : userName
        nameLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium) // 🔥 폰트 축소 (12 → 10)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 거리 라벨 (축소)
        let distanceLabel = UILabel()
        distanceLabel.font = UIFont.systemFont(ofSize: 8, weight: .regular) // 🔥 폰트 축소 (10 → 8)
        distanceLabel.textAlignment = .center
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.tag = 100 + index
        
        // 상태 라벨 (축소)
        let statusLabel = UILabel()
        statusLabel.font = UIFont.systemFont(ofSize: 8, weight: .semibold) // 🔥 폰트 축소 (10 → 8)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.tag = 200 + index
        
        // UI 조립 (여백 축소)
        card.addSubview(profileView)
        card.addSubview(nameLabel)
        card.addSubview(distanceLabel)
        card.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            profileView.topAnchor.constraint(equalTo: card.topAnchor, constant: 4), // 🔥 여백 축소 (6 → 4)
            profileView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            profileView.widthAnchor.constraint(equalToConstant: 20), // 🔥 크기 축소 (24 → 20)
            profileView.heightAnchor.constraint(equalToConstant: 20),
            
            iconLabel.centerXAnchor.constraint(equalTo: profileView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: profileView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: profileView.bottomAnchor, constant: 2), // 🔥 여백 축소 (4 → 2)
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -2),
            
            distanceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1), // 🔥 여백 축소 (2 → 1)
            distanceLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 2),
            distanceLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -2),
            
            statusLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 1),
            statusLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 2),
            statusLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -2),
            statusLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -4) // 🔥 여백 축소 (6 → 4)
        ])
        
        return card
    }
    
    // MARK: - 멤버 상태 카드 레이아웃
    private func layoutMemberStatusCards(in container: UIView) {
        guard !memberStatusCards.isEmpty else { return }
        
        let columns = 4 // 🔥 4열로 변경 (한 줄에 4명)
        let cardWidth: CGFloat = 70 // 🔥 카드 폭 축소 (80 → 70)
        let cardHeight: CGFloat = 90 // 🔥 카드 높이 축소 (100 → 90)
        let spacing: CGFloat = 6 // 🔥 간격 축소 (8 → 6)
        
        for (index, card) in memberStatusCards.enumerated() {
            let row = index / columns
            let col = index % columns
            
            let x = CGFloat(col) * (cardWidth + spacing) + 4
            let y = CGFloat(row) * (cardHeight + spacing) + 4
            
            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: x),
                card.topAnchor.constraint(equalTo: container.topAnchor, constant: y),
                card.widthAnchor.constraint(equalToConstant: cardWidth),
                card.heightAnchor.constraint(equalToConstant: cardHeight)
            ])
        }
        
        // 컨테이너 높이 설정
        let rows = (memberStatusCards.count + columns - 1) / columns
        let totalHeight = CGFloat(rows) * cardHeight + CGFloat(rows - 1) * spacing + 8
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: totalHeight)
        ])
    }
    
    // MARK: - 마커 범례 업데이트
    private func updateMarkerLegend() {
        guard let stackView = markerInfoView.viewWithTag(2000) as? UIStackView else { return }
        
        // 기존 아이템들 제거
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 새로운 범례 아이템들 추가
        for memberData in roomMembers {
            let legendItem = createLegendItem(memberData: memberData)
            stackView.addArrangedSubview(legendItem)
        }
    }
    
    // MARK: - 범례 아이템 생성
    private func createLegendItem(memberData: (user: User, member: RoomMember)) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let userName = memberData.user.name ?? memberData.user.userID ?? "Unknown"
        let userID = memberData.user.userID ?? "Unknown"
        let isCurrentUser = (userID == parentRoomDetail?.currentUserID)
        let userColor = memberColors[userID] ?? UIColor.systemGray
        
        // 컬러 인디케이터
        let colorIndicator = UIView()
        colorIndicator.backgroundColor = userColor
        colorIndicator.layer.cornerRadius = 6
        colorIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // 이름 라벨
        let nameLabel = UILabel()
        nameLabel.text = isCurrentUser ? "\(userName) (나)" : userName
        nameLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        nameLabel.textColor = UIColor.label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(colorIndicator)
        container.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            colorIndicator.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            colorIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 12),
            colorIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            nameLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 8),
            nameLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            
            container.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        return container
    }
    
    // MARK: - 멤버 마커 업데이트
    private func updateMemberMarkers() {
        // 기존 멤버 마커들 제거 (출발지 마커 제외)
        let memberAnnotations = mapView.annotations.filter { annotation in
            return annotation.title != "출발지"
        }
        mapView.removeAnnotations(memberAnnotations)
        
        // 새로운 멤버 마커들 추가
        for memberData in roomMembers {
            let user = memberData.user
            let userID = user.userID ?? "Unknown"
            let userName = user.name ?? userID
            let isCurrentUser = (userID == parentRoomDetail?.currentUserID)
            
            let annotation = MemberAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: user.currentLatitude,
                longitude: user.currentLongitude
            )
            annotation.title = isCurrentUser ? "\(userName) (나)" : userName
            annotation.subtitle = "이동 중"
            annotation.userID = userID
            annotation.color = memberColors[userID] ?? UIColor.systemGray
            
            mapView.addAnnotation(annotation)
        }
    }
    
    // MARK: - 위치 시뮬레이션 시작
    private func startLocationSimulation() {
        print("🤖 위치 시뮬레이션 시작")
        
        // 각 멤버의 위치를 출발지로 점진적으로 이동
        memberLocationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.simulateMemberMovement()
        }
        
        // 실시간 상태 업데이트
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateMemberStatus()
        }
    }
    
    // MARK: - 멤버 이동 시뮬레이션
    private func simulateMemberMovement() {
        guard let room = currentRoom,
              let roomID = room.roomID else { return }
        
        let startLocation = CLLocationCoordinate2D(
            latitude: room.startLatitude,
            longitude: room.startLongitude
        )
        
        for memberData in roomMembers {
            let user = memberData.user
            guard let userID = user.userID else { continue }
            
            let currentLocation = CLLocationCoordinate2D(
                latitude: user.currentLatitude,
                longitude: user.currentLongitude
            )
            
            // 출발지까지의 거리 계산
            let currentCLLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
            let startCLLocation = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
            let distance = currentCLLocation.distance(from: startCLLocation)
            
            // 100m 이내에 있지 않으면 점진적으로 이동
            if distance > 100 {
                // 출발지 방향으로 이동 (매번 거리의 10-20%씩)
                let moveRatio = Double.random(in: 0.1...0.2)
                
                let newLatitude = currentLocation.latitude + (startLocation.latitude - currentLocation.latitude) * moveRatio
                let newLongitude = currentLocation.longitude + (startLocation.longitude - currentLocation.longitude) * moveRatio
                
                // 위치 업데이트
                let success = CoreDataManager.shared.updateUserLocation(
                    userID: userID,
                    latitude: newLatitude,
                    longitude: newLongitude
                )
                
                if success {
                    // 메모리에서도 업데이트
                    user.currentLatitude = newLatitude
                    user.currentLongitude = newLongitude
                    
                    print("🚶‍♂️ \(userID) 이동: \(Int(distance))m → 출발지")
                }
            }
        }
        
        // 지도 마커 업데이트
        updateMemberMarkers()
    }
    
    // MARK: - 멤버 상태 업데이트
    private func updateMemberStatus() {
        guard let room = currentRoom else { return }
        
        let startLocation = CLLocationCoordinate2D(
            latitude: room.startLatitude,
            longitude: room.startLongitude
        )
        let startCLLocation = CLLocation(latitude: startLocation.latitude, longitude: startLocation.longitude)
        
        var membersWithinRadius = 0
        
        for (index, memberData) in roomMembers.enumerated() {
            let user = memberData.user
            let userID = user.userID ?? "Unknown"
            
            let userLocation = CLLocationCoordinate2D(
                latitude: user.currentLatitude,
                longitude: user.currentLongitude
            )
            let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
            let distance = userCLLocation.distance(from: startCLLocation)
            
            // 상태 카드 업데이트
            if index < memberStatusCards.count {
                let card = memberStatusCards[index]
                
                if let distanceLabel = card.viewWithTag(100 + index) as? UILabel,
                   let statusLabel = card.viewWithTag(200 + index) as? UILabel {
                    
                    distanceLabel.text = "\(Int(distance))m"
                    
                    if distance <= 100 {
                        statusLabel.text = "✅ 도착"
                        statusLabel.textColor = .systemGreen
                        card.layer.borderColor = UIColor.systemGreen.cgColor
                        membersWithinRadius += 1
                    } else {
                        statusLabel.text = "🚶‍♂️ 이동중"
                        statusLabel.textColor = .systemOrange
                        card.layer.borderColor = (memberColors[userID] ?? UIColor.systemGray).cgColor
                    }
                }
            }
        }
        
        // 택시 호출 버튼 상태 업데이트
        updateCallButtonState(membersWithinRadius: membersWithinRadius)
    }
    
    // MARK: - 택시 호출 버튼 상태 업데이트
    private func updateCallButtonState(membersWithinRadius: Int) {
        let totalMembers = roomMembers.count
        let isOwner = parentRoomDetail?.isOwner ?? false
        
        DispatchQueue.main.async {
            if membersWithinRadius >= totalMembers {
                // 모든 멤버가 100m 이내에 있음
                if isOwner {
                    self.callButton.isEnabled = true
                    self.callButton.backgroundColor = UIColor.systemGreen
                    self.callButton.setTitle("🚕 택시 호출하기", for: .normal)
                } else {
                    self.callButton.isEnabled = false
                    self.callButton.backgroundColor = UIColor.systemBlue
                    self.callButton.setTitle("방장이 택시를 호출할 예정입니다", for: .normal)
                }
            } else {
                // 아직 모든 멤버가 모이지 않음
                self.callButton.isEnabled = false
                self.callButton.backgroundColor = UIColor.systemGray3
                self.callButton.setTitle("대기 중... (\(membersWithinRadius)/\(totalMembers)명 도착)", for: .normal)
            }
        }
    }
    
    // MARK: - 택시 호출 버튼 클릭
    @IBAction func callButtonClick(_ sender: UIButton) {
        print("🚕 택시 호출 버튼 클릭")
        
        guard let room = currentRoom,
              let roomID = room.roomID else { return }
        
        // 모든 멤버가 100m 이내에 있는지 최종 확인
        let allWithinRadius = CoreDataManager.shared.areAllMembersWithinRadius(roomID: roomID)
        
        if allWithinRadius {
            // 위치 업데이트 중단
            CoreDataManager.shared.stopLocationUpdatesForRoom(roomID: roomID)
            
            // 타이머 정리
            locationUpdateTimer?.invalidate()
            memberLocationUpdateTimer?.invalidate()
            
            print("✅ 모든 멤버 집합 완료 - Step 3으로 이동")
            
            // Step 3으로 이동 (부모에게 알림)
            parentRoomDetail?.showStepThree()
            
        } else {
            print("❌ 아직 모든 멤버가 집합하지 않음")
            
            let alert = UIAlertController(
                title: "잠시만요!",
                message: "아직 모든 멤버가 100m 이내로 모이지 않았습니다. 조금 더 기다려주세요.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }
    
    // MARK: - 메모리 관리
    deinit {
        locationUpdateTimer?.invalidate()
        memberLocationUpdateTimer?.invalidate()
        locationManager?.stopUpdatingLocation()
        print("🗑️ StepTwoController 해제")
    }
}

// MARK: - CLLocationManagerDelegate
extension StepTwoController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              let currentUserID = parentRoomDetail?.currentUserID else { return }
        
        // 현재 사용자 위치 업데이트
        let success = CoreDataManager.shared.updateUserLocation(
            userID: currentUserID,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        if success {
            // 메모리에서도 업데이트
            if let currentUserData = roomMembers.first(where: { $0.user.userID == currentUserID }) {
                currentUserData.user.currentLatitude = location.coordinate.latitude
                currentUserData.user.currentLongitude = location.coordinate.longitude
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
}

// MARK: - MKMapViewDelegate
extension StepTwoController: MKMapViewDelegate {
    // 100m 원형 오버레이 렌더링
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.strokeColor = UIColor.systemRed.withAlphaComponent(0.8)
            renderer.fillColor = UIColor.systemRed.withAlphaComponent(0.2)
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    // 마커 커스터마이징
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let memberAnnotation = annotation as? MemberAnnotation {
            let identifier = "MemberAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // 멤버별 색상으로 커스텀 마커 생성
            if let color = memberAnnotation.color {
                annotationView?.image = createCustomMarkerImage(color: color)
            }
            
            return annotationView
        }
        
        // 출발지 마커
        if annotation.title == "출발지" {
            let identifier = "StartAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                if let originalImage = UIImage(named: "taxi") {
                    let newSize = CGSize(width: 30, height: 30)
                    annotationView?.image = resizeImage(image: originalImage, targetSize: newSize)
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        return nil
    }
    
    // 커스텀 마커 이미지 생성
    private func createCustomMarkerImage(color: UIColor) -> UIImage {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            color.setFill()
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            path.fill()
            
            // 테두리 추가
            UIColor.white.setStroke()
            path.lineWidth = 2
            path.stroke()
        }
    }
    
    // 이미지 리사이즈 헬퍼
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

// MARK: - Custom Annotation Class
class MemberAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var subtitle: String?
    var userID: String?
    var color: UIColor?
}
