import UIKit

class StepOneController: UIViewController {
    @IBOutlet weak var firstView: UIView!
    @IBOutlet weak var dynamicContainer: UIView! // 동적으로 참여자 담는 부분
    @IBOutlet weak var startButton: UIButton! // 시작버튼
    @IBOutlet weak var exitButton: UIButton! // 나가기버튼
    @IBOutlet weak var personCostLabel: UILabel! // 인당 비용
    @IBOutlet weak var endLabel: UILabel! // 도착지
    @IBOutlet weak var startLabel: UILabel! // 출발지
    @IBOutlet weak var startAndEndLabel: UILabel! // 출발지 -> 도착지 라벨
    
    // 부모 뷰 컨트롤러 참조
    weak var parentRoomDetail: RoomDetailViewController?
    
    // 멤버 관련 데이터
    var roomMembers: [RoomMember] = []
    var memberCards: [UIView] = []
    var memberJoinTimer: Timer?
    var memberReadyTimer: Timer?
    var currentMemberIndex = 0
    
    // 상단 라벨들
    var memberCountLabel: UILabel!
    var currentMembersLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 StepOneController 로드 시작")
        
        setupUI()
        loadRoomInfo()
        
        // 🔥 방장 자동 Ready 설정
        setOwnerReadyStatus()
        
        startMemberJoinSimulation()
        
        print("✅ StepOneController 로드 완료")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 버튼 초기 설정
        startButton.layer.cornerRadius = 8
        startButton.isEnabled = false
        startButton.backgroundColor = UIColor.systemGray3
        startButton.setTitle("준비 중...", for: .normal)
        
        exitButton.layer.cornerRadius = 8
        exitButton.backgroundColor = UIColor.systemRed
        exitButton.setTitle("나가기", for: .normal)
        
        // 컨테이너 스타일링
        dynamicContainer.layer.cornerRadius = 12
        dynamicContainer.backgroundColor = UIColor.systemBackground
        dynamicContainer.layer.borderWidth = 1
        dynamicContainer.layer.borderColor = UIColor.systemGray4.cgColor
        
        
        print("=== 뷰 위치 정보 ===")
           print("firstView frame: \(firstView.frame)")
           print("dynamicContainer frame: \(dynamicContainer.frame)")
           print("startButton frame: \(startButton.frame)")
           
         
        
        dynamicContainer.clipsToBounds = true
        
        print("✅ StepOneController UI 설정 완료")
    }
    
    // MARK: - 방 정보 로드
    private func loadRoomInfo() {
        guard let parentRoom = parentRoomDetail?.currentRoom else {
            print("❌ 부모 방 정보가 없습니다")
            return
        }
        
        // 방 기본 정보 표시
        startLabel.text = parentRoom.startLocation
        endLabel.text = parentRoom.endLocation
        startAndEndLabel.text = "\(parentRoom.startLocation ?? "") → \(parentRoom.endLocation ?? "")"
        
        // 비용 정보 표시
        let totalCost = Int(parentRoom.estimatedCost)
        let costPerPerson = Int(parentRoom.costPerPerson)
        personCostLabel.text = "총 \(NumberFormatter.localizedString(from: NSNumber(value: totalCost), number: .decimal))원 / 인당 \(NumberFormatter.localizedString(from: NSNumber(value: costPerPerson), number: .decimal))원"
        
        // 현재 방 멤버들 로드
        if let roomID = parentRoom.roomID {
            roomMembers = CoreDataManager.shared.getRoomMembers(roomID: roomID)
        }
        
        // 동적 컨테이너 초기 설정
        setupDynamicContainer(maxMembers: Int(parentRoom.maxMembers))
        
        print("✅ 방 정보 로드 완료")
        print("   - 최대 인원: \(parentRoom.maxMembers)명")
        print("   - 현재 멤버 수: \(roomMembers.count)명")
    }
    
    // MARK: - 🔥 방장 자동 Ready 설정
    private func setOwnerReadyStatus() {
        guard let parentRoom = parentRoomDetail?.currentRoom,
              let roomID = parentRoom.roomID,
              let ownerID = parentRoom.ownerID else {
            print("❌ 방장 정보가 없습니다")
            return
        }
        
        // 방장을 자동으로 Ready 상태로 설정
        let success = CoreDataManager.shared.setOwnerReady(roomID: roomID)
        
        if success {
            print("✅ 방장 자동 Ready 설정 완료: \(ownerID)")
            
            // 멤버 목록 새로고침
            roomMembers = CoreDataManager.shared.getRoomMembers(roomID: roomID)
            updateMemberDisplay()
            checkAllMembersReady()
        } else {
            print("❌ 방장 Ready 설정 실패")
        }
    }
    
    // MARK: - 동적 컨테이너 설정 (🔥 단순하게 내용만 추가)
    private func setupDynamicContainer(maxMembers: Int) {
        // 기존 서브뷰 제거
        dynamicContainer.subviews.forEach { $0.removeFromSuperview() }
        memberCards.removeAll()
        
        // 🔥 컨테이너 스타일링 (위치는 스토리보드에서 이미 설정됨)
        dynamicContainer.layer.cornerRadius = 12
        dynamicContainer.backgroundColor = UIColor.systemBackground
        dynamicContainer.layer.borderWidth = 1
        dynamicContainer.layer.borderColor = UIColor.systemGray4.cgColor
        
        // 상단 라벨들 추가
        addHeaderLabels(to: dynamicContainer, maxMembers: maxMembers)
        
        // 멤버 카드들을 위한 컨테이너 추가
        let memberGridContainer = UIView()
        memberGridContainer.translatesAutoresizingMaskIntoConstraints = false
        dynamicContainer.addSubview(memberGridContainer)
        
        NSLayoutConstraint.activate([
            memberGridContainer.topAnchor.constraint(equalTo: currentMembersLabel.bottomAnchor, constant: 16),
            memberGridContainer.leadingAnchor.constraint(equalTo: dynamicContainer.leadingAnchor, constant: 16),
            memberGridContainer.trailingAnchor.constraint(equalTo: dynamicContainer.trailingAnchor, constant: -16),
            memberGridContainer.bottomAnchor.constraint(equalTo: dynamicContainer.bottomAnchor, constant: -16)
        ])
        
        // 멤버 카드들 생성
        createMemberCards(in: memberGridContainer, maxMembers: maxMembers)
        
        // 초기 멤버 상태 업데이트
        updateMemberDisplay()
        
        print("✅ 동적 컨테이너 설정 완료 - 스토리보드 위치 유지, 최대 \(maxMembers)명")
    }
    
    // MARK: - 상단 라벨 추가 (🔥 dynamicContainer에 직접 추가)
    private func addHeaderLabels(to parentView: UIView, maxMembers: Int) {
        // "참여 멤버" 라벨
        memberCountLabel = UILabel()
        memberCountLabel.text = "참여 멤버"
        memberCountLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        memberCountLabel.textColor = UIColor.label
        memberCountLabel.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(memberCountLabel)
        
        // "현재 인원" 라벨
        currentMembersLabel = UILabel()
        currentMembersLabel.text = "\(roomMembers.count)/\(maxMembers)명"
        currentMembersLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        currentMembersLabel.textColor = UIColor.systemOrange
        currentMembersLabel.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(currentMembersLabel)
        
        NSLayoutConstraint.activate([
            memberCountLabel.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 16),
            memberCountLabel.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 16),
            
            currentMembersLabel.centerYAnchor.constraint(equalTo: memberCountLabel.centerYAnchor),
            currentMembersLabel.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -16)
        ])
    }
    
    // MARK: - 멤버 카드 생성 (🔥 레이아웃 완전 수정)
    private func createMemberCards(in container: UIView, maxMembers: Int) {
        let columns = 2 // 2열 고정
        let rows = (maxMembers + 1) / 2 // 필요한 행 수 계산
        
        // 🔥 화면 크기 기반 카드 크기 계산
        let containerWidth = UIScreen.main.bounds.width - 64 // 좌우 여백 32씩
        let horizontalSpacing: CGFloat = 12
        let cardWidth = (containerWidth - horizontalSpacing) / 2 // 2열이므로 2로 나누기
        let cardHeight: CGFloat = 90
        let verticalSpacing: CGFloat = 16
        
        // 🔥 스택뷰 사용으로 확실한 레이아웃
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.distribution = .fillEqually
        mainStackView.spacing = verticalSpacing
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(mainStackView)
        
        // 메인 스택뷰 제약조건
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: container.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        // 행별로 스택뷰 생성
        for row in 0..<rows {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.distribution = .fillEqually
            rowStackView.spacing = horizontalSpacing
            rowStackView.translatesAutoresizingMaskIntoConstraints = false
            
            // 해당 행의 카드들 추가
            let startIndex = row * columns
            let endIndex = min(startIndex + columns, maxMembers)
            
            for i in startIndex..<endIndex {
                let memberCard = createSingleMemberCard(index: i)
                memberCards.append(memberCard)
                rowStackView.addArrangedSubview(memberCard)
                
                // 카드 높이 설정
                NSLayoutConstraint.activate([
                    memberCard.heightAnchor.constraint(equalToConstant: cardHeight),
                    memberCard.widthAnchor.constraint(equalToConstant: cardWidth)
                ])
            }
            
            // 마지막 행이 홀수개면 빈 공간 추가
            if endIndex - startIndex == 1 && columns == 2 {
                let emptyView = UIView()
                emptyView.translatesAutoresizingMaskIntoConstraints = false
                rowStackView.addArrangedSubview(emptyView)
                
                NSLayoutConstraint.activate([
                    emptyView.widthAnchor.constraint(equalToConstant: cardWidth)
                ])
            }
            
            mainStackView.addArrangedSubview(rowStackView)
        }
        
        // 🔥 컨테이너 높이 설정
        let totalHeight = CGFloat(rows) * cardHeight + CGFloat(rows - 1) * verticalSpacing
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: totalHeight)
        ])
        
        print("✅ 멤버 카드 생성 완료 - \(maxMembers)개 카드, \(rows)행 \(columns)열")
    }
    
    // MARK: - 개별 멤버 카드 생성 (🔥 크기 최적화)
    private func createSingleMemberCard(index: Int) -> UIView {
        let cardView = UIView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.layer.cornerRadius = 8
        cardView.layer.borderWidth = 2
        cardView.backgroundColor = UIColor.systemBackground
        
        // 프로필 이미지 (원형)
        let profileImageView = UIView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.layer.cornerRadius = 16
        profileImageView.backgroundColor = UIColor.systemGray4
        cardView.addSubview(profileImageView)
        
        // 프로필 아이콘
        let iconLabel = UILabel()
        iconLabel.text = "👤"
        iconLabel.font = UIFont.systemFont(ofSize: 14)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.addSubview(iconLabel)
        
        // 이름 라벨
        let nameLabel = UILabel()
        nameLabel.text = "대기 중"
        nameLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.systemGray
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.tag = 100 // 나중에 찾기 위한 태그
        cardView.addSubview(nameLabel)
        
        // 상태 라벨
        let statusLabel = UILabel()
        statusLabel.text = "빈 자리"
        statusLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        statusLabel.textAlignment = .center
        statusLabel.textColor = UIColor.systemGray2
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.tag = 200 // 나중에 찾기 위한 태그
        cardView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 6),
            profileImageView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 32),
            profileImageView.heightAnchor.constraint(equalToConstant: 32),
            
            iconLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 2),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -2),
            
            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 2),
            statusLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -2),
            statusLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -4)
        ])
        
        return cardView
    }
    
    // MARK: - 멤버 시뮬레이션 시작
    private func startMemberJoinSimulation() {
        guard let parentRoom = parentRoomDetail?.currentRoom,
              let roomID = parentRoom.roomID else { return }
        
        let maxMembers = Int(parentRoom.maxMembers)
        let currentMemberCount = roomMembers.count
        
        // 이미 정원이 찬 경우
        if currentMemberCount >= maxMembers {
            print("✅ 이미 방이 가득함 - 시뮬레이션 불필요")
            checkAllMembersReady()
            return
        }
        
        print("🤖 멤버 입장 시뮬레이션 시작 - 현재 \(currentMemberCount)명, 목표 \(maxMembers)명")
        
        // 5초 후부터 멤버들이 입장하기 시작
        memberJoinTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            self?.simulateMemberJoin()
        }
    }
    
    // MARK: - 멤버 입장 시뮬레이션
    private func simulateMemberJoin() {
        guard let parentRoom = parentRoomDetail?.currentRoom,
              let roomID = parentRoom.roomID else { return }
        
        let maxMembers = Int(parentRoom.maxMembers)
        let currentMemberCount = roomMembers.count
        
        // 정원이 찬 경우 타이머 중지
        if currentMemberCount >= maxMembers {
            memberJoinTimer?.invalidate()
            memberJoinTimer = nil
            
            // 모든 멤버 입장 완료 후 Ready 시뮬레이션 시작
            startReadySimulation()
            return
        }
        
        // 임의의 사용자 입장 시뮬레이션
        let success = CoreDataManager.shared.simulateMemberJoin(roomID: roomID)
        
        if success {
            // 멤버 목록 새로고침
            roomMembers = CoreDataManager.shared.getRoomMembers(roomID: roomID)
            updateMemberDisplay()
            
            print("🤖 멤버 입장 시뮬레이션 성공 - 현재 \(roomMembers.count)명")
        }
    }
    
    // MARK: - Ready 시뮬레이션 시작
    private func startReadySimulation() {
        print("🤖 Ready 시뮬레이션 시작")
        
        // 3초 후부터 멤버들이 Ready하기 시작
        memberReadyTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            self?.simulateMemberReady()
        }
    }
    
    // MARK: - 멤버 Ready 시뮬레이션
    private func simulateMemberReady() {
        guard let parentRoom = parentRoomDetail?.currentRoom,
              let roomID = parentRoom.roomID else { return }
        
        // 🔥 방장 제외하고 아직 Ready하지 않은 멤버 찾기
        let notReadyMembers = roomMembers.filter { member in
            return !member.isReady && member.userID != parentRoomDetail?.currentUserID
        }
        
        if notReadyMembers.isEmpty {
            // 모든 멤버가 Ready됨
            memberReadyTimer?.invalidate()
            memberReadyTimer = nil
            checkAllMembersReady()
            return
        }
        
        // 랜덤한 멤버를 Ready로 변경
        if let randomMember = notReadyMembers.randomElement(),
           let userID = randomMember.userID {
            
            let success = CoreDataManager.shared.toggleUserReadyStatus(roomID: roomID, userID: userID)
            
            if success {
                // 멤버 목록 새로고침
                roomMembers = CoreDataManager.shared.getRoomMembers(roomID: roomID)
                updateMemberDisplay()
                
                // 🔥 Ready 상태 변경 후 즉시 체크
                checkAllMembersReady()
                
                print("🤖 \(userID) Ready 상태 변경 완료")
            }
        }
    }
    
    // MARK: - 멤버 표시 업데이트
    private func updateMemberDisplay() {
        // 상단 인원 수 라벨 업데이트
        if let parentRoom = parentRoomDetail?.currentRoom {
            let maxMembers = Int(parentRoom.maxMembers)
            currentMembersLabel.text = "\(roomMembers.count)/\(maxMembers)명"
        }
        
        // 각 멤버 카드 업데이트
        for (index, memberCard) in memberCards.enumerated() {
            if index < roomMembers.count {
                // 해당 인덱스에 멤버가 있는 경우
                let member = roomMembers[index]
                updateMemberCard(memberCard, with: member)
            } else {
                // 빈 자리인 경우
                updateEmptyMemberCard(memberCard)
            }
        }
        
        print("🔄 멤버 표시 업데이트 완료 - 현재 \(roomMembers.count)명")
    }
    
    // MARK: - 개별 멤버 카드 업데이트
    private func updateMemberCard(_ cardView: UIView, with member: RoomMember) {
        guard let nameLabel = cardView.viewWithTag(100) as? UILabel,
              let statusLabel = cardView.viewWithTag(200) as? UILabel else { return }
        
        // 사용자 정보 가져오기
        if let userID = member.userID,
           let user = CoreDataManager.shared.getUser(userID: userID) {
            
            nameLabel.text = user.name ?? userID
            nameLabel.textColor = UIColor.label
            
            // 방장인지 확인
            let isOwner = (userID == parentRoomDetail?.currentUserID)
            
            if isOwner {
                // 방장인 경우 - 항상 Ready 상태로 표시
                cardView.layer.borderColor = UIColor.systemBlue.cgColor
                statusLabel.text = "방장 (Ready)"
                statusLabel.textColor = UIColor.systemBlue
                
                // 방장 아이콘 추가
                if let profileView = cardView.subviews.first(where: { $0.layer.cornerRadius > 0 }) {
                    profileView.backgroundColor = UIColor.systemBlue
                }
            } else {
                // 일반 멤버인 경우
                if member.isReady {
                    cardView.layer.borderColor = UIColor.systemGreen.cgColor
                    statusLabel.text = "준비됨"
                    statusLabel.textColor = UIColor.systemGreen
                    
                    if let profileView = cardView.subviews.first(where: { $0.layer.cornerRadius > 0 }) {
                        profileView.backgroundColor = UIColor.systemGreen
                    }
                } else {
                    cardView.layer.borderColor = UIColor.systemOrange.cgColor
                    statusLabel.text = "참여중"
                    statusLabel.textColor = UIColor.systemOrange
                    
                    if let profileView = cardView.subviews.first(where: { $0.layer.cornerRadius > 0 }) {
                        profileView.backgroundColor = UIColor.systemOrange
                    }
                }
            }
        }
    }
    
    // MARK: - 빈 멤버 카드 업데이트
    private func updateEmptyMemberCard(_ cardView: UIView) {
        guard let nameLabel = cardView.viewWithTag(100) as? UILabel,
              let statusLabel = cardView.viewWithTag(200) as? UILabel else { return }
        
        cardView.layer.borderColor = UIColor.systemGray4.cgColor
        nameLabel.text = "대기 중"
        nameLabel.textColor = UIColor.systemGray
        statusLabel.text = "빈 자리"
        statusLabel.textColor = UIColor.systemGray2
        
        if let profileView = cardView.subviews.first(where: { $0.layer.cornerRadius > 0 }) {
            profileView.backgroundColor = UIColor.systemGray4
        }
    }
    
    // MARK: - 🔥 모든 멤버 Ready 확인 (핵심 수정)
    private func checkAllMembersReady() {
        guard let parentRoom = parentRoomDetail?.currentRoom,
              let roomID = parentRoom.roomID else {
            print("❌ 방 정보가 없습니다")
            return
        }
        
        // 🔥 CoreDataManager를 통해 정확한 Ready 상태 확인
        let allReady = CoreDataManager.shared.areAllMembersReady(roomID: roomID)
        let memberCount = roomMembers.count
        
        print("🔍 Ready 상태 확인:")
        print("   - 전체 멤버 수: \(memberCount)")
        print("   - 모든 멤버 Ready: \(allReady)")
        
        // 🔥 개별 멤버 Ready 상태 출력 (디버깅용)
        for member in roomMembers {
            print("   - \(member.userID ?? "Unknown"): Ready = \(member.isReady)")
        }
        
        DispatchQueue.main.async {
            if allReady && memberCount > 1 {
                // 🔥 모든 멤버가 Ready이고 혼자가 아닌 경우
                self.startButton.isEnabled = true
                self.startButton.backgroundColor = UIColor.systemOrange
                self.startButton.setTitle("시작", for: .normal)
                
                print("✅ 모든 멤버 준비 완료 - 시작 버튼 활성화")
            } else if memberCount <= 1 {
                // 혼자인 경우
                self.startButton.isEnabled = false
                self.startButton.backgroundColor = UIColor.systemGray3
                self.startButton.setTitle("다른 멤버를 기다리는 중...", for: .normal)
                
                print("⏳ 혼자 상태 - 다른 멤버 대기 중")
            } else {
                // 아직 모든 멤버가 Ready가 아닌 경우
                self.startButton.isEnabled = false
                self.startButton.backgroundColor = UIColor.systemGray3
                self.startButton.setTitle("준비 중...", for: .normal)
                
                print("⏳ 일부 멤버 Ready 대기 중")
            }
        }
    }
    
    // MARK: - 버튼 액션
    @IBAction func startButtonClick(_ sender: UIButton) {
        print("🚀 시작 버튼 클릭")
        
        // 타이머 정리
        memberJoinTimer?.invalidate()
        memberReadyTimer?.invalidate()
        
        // 부모에게 알림
        parentRoomDetail?.handleStartButtonClicked()
    }
    
    @IBAction func exitButtonClick(_ sender: UIButton) {
        print("🚪 나가기 버튼 클릭")
        
        // 타이머 정리
        memberJoinTimer?.invalidate()
        memberReadyTimer?.invalidate()
        
        // 부모에게 알림
        parentRoomDetail?.handleExitButtonClicked()
    }
    
    // MARK: - 메모리 관리
    deinit {
        memberJoinTimer?.invalidate()
        memberReadyTimer?.invalidate()
        print("🗑️ StepOneController 해제")
    }
}
