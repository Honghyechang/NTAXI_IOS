import UIKit

class SecondSetViewController: UIViewController {
    
    @IBOutlet weak var createButton: UIButton! // 만들기버튼 활성화비활성화
    @IBOutlet weak var secondSetErrorMessage: UILabel! // 에러메시지
    @IBOutlet weak var onePersonCost: UILabel! // 인당비용 즉, 맴버가 바뀔때마다 구해진 값을 여기서 보여준다.
    @IBOutlet weak var costLabel: UILabel! // 총 비용 앞서 페이지에서 받은 비용을 보여준다.
    @IBOutlet weak var memberSetting: UISegmentedControl! // 맴버 바꾸기 세그먼트
    
    // 부모 뷰 컨트롤러 참조
    weak var parentCreateRoom: CreateRoomViewController?
    
    // 전달받은 데이터
    var totalCost: Int = 0
    var currentMemberCount: Int = 2
    var costPerPerson: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 SecondSetViewController 로드 시작")
        
        setupUI()
        
        print("✅ SecondSetViewController 로드 완료")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 인원 선택 초기값 (2명)
        memberSetting.selectedSegmentIndex = 0
        memberSetting.setTitle("2명", forSegmentAt: 0)
        memberSetting.setTitle("3명", forSegmentAt: 1)
        memberSetting.setTitle("4명", forSegmentAt: 2)
        
        // 방 만들기 버튼 초기 설정
        createButton.layer.cornerRadius = 8
        createButton.isEnabled = false
        createButton.backgroundColor = UIColor.systemGray3
        createButton.setTitle("조건 미충족", for: .normal)
        
        // 🔥 버튼 우선순위 설정 (버튼 클릭 보장)
        setupButtonPriority()
        
        // 에러 메시지 초기 설정
        secondSetErrorMessage.isHidden = true
        secondSetErrorMessage.textColor = .red
        secondSetErrorMessage.numberOfLines = 0
        
        print("✅ SecondSetViewController UI 설정 완료")
    }
    
    // MARK: - 🔥 버튼 클릭 우선순위 보장
    private func setupButtonPriority() {
        // 방 만들기 버튼에 높은 우선순위 부여
        createButton.isUserInteractionEnabled = true
        createButton.isExclusiveTouch = true // 🔥 독점 터치 보장
        
        print("🔥 방 만들기 버튼 우선순위 설정 완료")
    }
    
    // MARK: - 첫 번째 페이지에서 데이터 받기
    func receiveDataFromFirstPage(totalCost: Int, memberCount: Int) {
        print("📥 첫 번째 페이지에서 데이터 수신 - 총비용: \(totalCost)원, 인원: \(memberCount)명")
        
        self.totalCost = totalCost
        self.currentMemberCount = memberCount
        
        // 인원에 따라 세그먼트 설정
        switch memberCount {
        case 2:
            memberSetting.selectedSegmentIndex = 0
        case 3:
            memberSetting.selectedSegmentIndex = 1
        case 4:
            memberSetting.selectedSegmentIndex = 2
        default:
            memberSetting.selectedSegmentIndex = 0
            self.currentMemberCount = 2
        }
        
        // UI 업데이트
        updateCostDisplay()
        
        // 🔥 처음 로드 시에도 조건 확인 (핵심 수정)
        checkCreateButtonCondition()
    }
    
    // MARK: - 비용 표시 업데이트
    private func updateCostDisplay() {
        // 총 비용 표시
        costLabel.text = "\(NumberFormatter.localizedString(from: NSNumber(value: totalCost), number: .decimal))원"
        
        // 인당 비용 계산 및 표시
        costPerPerson = totalCost / currentMemberCount
        onePersonCost.text = "\(NumberFormatter.localizedString(from: NSNumber(value: costPerPerson), number: .decimal))원"
        
        print("💰 비용 표시 업데이트 - 총: \(totalCost)원, 인당: \(costPerPerson)원")
    }
    
    // MARK: - 현재 선택된 인원 수 가져오기
    private func getCurrentMemberCount() -> Int {
        switch memberSetting.selectedSegmentIndex {
        case 0: return 2
        case 1: return 3
        case 2: return 4
        default: return 2
        }
    }
    
    // MARK: - 방 만들기 버튼 조건 확인 (개선된 버전)
    private func checkCreateButtonCondition() {
        guard let parentCreateRoom = parentCreateRoom else {
            print("❌ 부모 뷰 컨트롤러 참조가 없습니다")
            return
        }
        
        // 🔥 현재 인원 수에 맞춰 부모에게 인원 변경 알림 (중요!)
        parentCreateRoom.handleMemberCountChange(currentMemberCount)
        
        // 부모에게 잔액 조건 확인 요청
        let balanceCheck = parentCreateRoom.checkBalanceCondition()
        
        if balanceCheck.isValid {
            // 조건 충족 - 버튼 활성화
            createButton.isEnabled = true
            createButton.backgroundColor = UIColor.systemOrange
            createButton.setTitle("방 만들기", for: .normal)
            hideError()
            
            print("✅ 방 만들기 조건 충족")
        } else {
            // 조건 미충족 - 버튼 비활성화
            createButton.isEnabled = false
            createButton.backgroundColor = UIColor.systemGray3
            createButton.setTitle("잔액 부족", for: .normal)
            
            if let errorMessage = balanceCheck.errorMessage {
                // 🔥 개선된 에러 메시지 표시
                let improvedErrorMessage = createDetailedErrorMessage()
                showError(improvedErrorMessage)
            }
            
            print("❌ 방 만들기 조건 미충족 - 잔액 부족")
        }
    }
    
    // 🔥 자세한 에러 메시지 생성 (새로 추가)
    private func createDetailedErrorMessage() -> String {
        guard let parentCreateRoom = parentCreateRoom else {
            return "오류가 발생했습니다."
        }
        
        let currentBalance = parentCreateRoom.currentUserBalance
        let requiredBalance = Int(Double(costPerPerson) * 1.2)
        let shortageAmount = requiredBalance - currentBalance
        
        let message = """
        방 만들기를 위해 예상 비용의 20% 추가 금액이 필요합니다.
        
        현재 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: currentBalance), number: .decimal))원
        필요 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: requiredBalance), number: .decimal))원
        부족한 금액: \(NumberFormatter.localizedString(from: NSNumber(value: shortageAmount), number: .decimal))원
        """
        
        print("💰 에러 메시지 생성:")
        print("   - 현재 잔액: \(currentBalance)원")
        print("   - 필요 잔액: \(requiredBalance)원")
        print("   - 부족한 금액: \(shortageAmount)원")
        
        return message
    }
    
    private func showError(_ message: String) {
        secondSetErrorMessage.text = message
        secondSetErrorMessage.isHidden = false
    }
    
    private func hideError() {
        secondSetErrorMessage.isHidden = true
        secondSetErrorMessage.text = ""
    }
    
    // 만들기 버튼은 인당비용의 20%의 비용이 더 있을경우 활성화하여 만들 수 있도록한다 없다면 에러메시지에서 보여준다.
    @IBAction func createButtonClick(_ sender: Any) {
        print("🚪 방 만들기 버튼 클릭")
        
        guard let parentCreateRoom = parentCreateRoom else {
            print("❌ 부모 뷰 컨트롤러 참조가 없습니다")
            return
        }
        
        // 최종 조건 재확인
        let balanceCheck = parentCreateRoom.checkBalanceCondition()
        
        if balanceCheck.isValid {
            print("✅ 모든 조건 충족 - 방 생성 진행")
            parentCreateRoom.handleCreateRoom()
        } else {
            print("❌ 조건 미충족으로 방 생성 불가")
            // 🔥 개선된 에러 메시지 표시
            let improvedErrorMessage = createDetailedErrorMessage()
            showError(improvedErrorMessage)
        }
    }
    
    // 맴버가 바뀌면 cost비용을 인원수로 나누어서 인당 비용을 구해서 보여준다.
    @IBAction func memberChange(_ sender: UISegmentedControl) {
        // 선택된 인원 수 가져오기
        currentMemberCount = getCurrentMemberCount()
        
        print("🧑‍🤝‍🧑 인원 선택 변경: \(currentMemberCount)명")
        
        // 부모에게 인원 변경 알림
        parentCreateRoom?.handleMemberCountChange(currentMemberCount)
        
        // 인당 비용 재계산 및 표시 업데이트
        updateCostDisplay()
        
        // 방 만들기 버튼 조건 재확인
        checkCreateButtonCondition()
    }
}
