import UIKit

class StepSevenController: UIViewController {
    
    @IBOutlet weak var myBalanceChange: UILabel!
    @IBOutlet weak var onePersonCost: UILabel!
    @IBOutlet weak var totalCost: UILabel!
    
    // 부모 뷰 컨트롤러 참조
    weak var parentRoomDetail: RoomDetailViewController?
    
    // 계산된 비용들
    var actualTotalCost: Int = 0
    var actualCostPerPerson: Int = 0
    var previousBalance: Int = 0
    var newBalance: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 StepSevenController 로드 시작")
        
        calculateActualCosts()
        setupUI()
        updateBalance()
        
        print("✅ StepSevenController 로드 완료")
    }
    
    // MARK: - 실제 비용 계산
    private func calculateActualCosts() {
        guard let room = parentRoomDetail?.currentRoom,
              let currentUserID = parentRoomDetail?.currentUserID else { return }
        
        let estimatedCost = Int(room.estimatedCost)
        let currentMembers = Int(room.currentMembers)
        
        // 실제 비용 = 예상 비용의 ±10% 랜덤
        let variation = Double.random(in: 0.9...1.1)
        actualTotalCost = Int(Double(estimatedCost) * variation)
        actualCostPerPerson = actualTotalCost / currentMembers
        
        // 현재 사용자 잔액 가져오기
        if let user = CoreDataManager.shared.getUser(userID: currentUserID) {
            previousBalance = Int(user.balance)
            newBalance = previousBalance - actualCostPerPerson
        }
        
        print("💰 실제 비용 계산 완료:")
        print("   - 예상 총비용: \(estimatedCost)원")
        print("   - 실제 총비용: \(actualTotalCost)원 (변동률: \(Int(variation * 100))%)")
        print("   - 실제 인당비용: \(actualCostPerPerson)원")
        print("   - 이전 잔액: \(previousBalance)원")
        print("   - 새 잔액: \(newBalance)원")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 잔액 변화 라벨 설정
        setupBalanceChangeLabel()
        
        // 인당 비용 라벨 설정
        setupCostLabels()
        
        print("✅ Step 7 UI 설정 완료")
    }
    
    // MARK: - 잔액 변화 라벨 설정
        private func setupBalanceChangeLabel() {
            let balanceText = "\(NumberFormatter.localizedString(from: NSNumber(value: previousBalance), number: .decimal))원 → \(NumberFormatter.localizedString(from: NSNumber(value: newBalance), number: .decimal))원"
            
            // NSAttributedString으로 스타일 적용
            let attributedText = NSMutableAttributedString(string: balanceText)
            
            // 이전 잔액 (검은색)
            let previousRange = (balanceText as NSString).range(of: "\(NumberFormatter.localizedString(from: NSNumber(value: previousBalance), number: .decimal))원")
            attributedText.addAttributes([
                .foregroundColor: UIColor.label,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
            ], range: previousRange)
            
            // 화살표 (회색)
            let arrowRange = (balanceText as NSString).range(of: " → ")
            attributedText.addAttributes([
                .foregroundColor: UIColor.systemGray,
                .font: UIFont.systemFont(ofSize: 18, weight: .medium)
            ], range: arrowRange)
            
            // 🔥 새 잔액 (빨간색 - 취소선 제거)
            let newRange = (balanceText as NSString).range(of: "\(NumberFormatter.localizedString(from: NSNumber(value: newBalance), number: .decimal))원", options: .backwards)
            attributedText.addAttributes([
                .foregroundColor: UIColor.systemRed,
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
                // 🔥 strikethroughStyle 제거
            ], range: newRange)
            
            myBalanceChange.attributedText = attributedText
            myBalanceChange.textAlignment = .center
            myBalanceChange.numberOfLines = 0
            
            // 배경 스타일링
            myBalanceChange.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
            myBalanceChange.layer.cornerRadius = 8
            myBalanceChange.layer.masksToBounds = true
            myBalanceChange.layer.borderWidth = 1
            myBalanceChange.layer.borderColor = UIColor.systemRed.cgColor
        }
    // MARK: - 비용 라벨들 설정
    private func setupCostLabels() {
        // 인당 비용
        onePersonCost.text = "인당 \(NumberFormatter.localizedString(from: NSNumber(value: actualCostPerPerson), number: .decimal))원"
        onePersonCost.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        onePersonCost.textColor = UIColor.systemOrange
        onePersonCost.textAlignment = .center
        
        // 배경 스타일링
        onePersonCost.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.1)
        onePersonCost.layer.cornerRadius = 8
        onePersonCost.layer.masksToBounds = true
        onePersonCost.layer.borderWidth = 1
        onePersonCost.layer.borderColor = UIColor.systemOrange.cgColor
        
        // 총 비용
        totalCost.text = "총 \(NumberFormatter.localizedString(from: NSNumber(value: actualTotalCost), number: .decimal))원"
        totalCost.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        totalCost.textColor = UIColor.systemGray
        totalCost.textAlignment = .center
        
        // 배경 스타일링
        totalCost.backgroundColor = UIColor.systemGray.withAlphaComponent(0.1)
        totalCost.layer.cornerRadius = 6
        totalCost.layer.masksToBounds = true
        totalCost.layer.borderWidth = 1
        totalCost.layer.borderColor = UIColor.systemGray.cgColor
    }
    
    // MARK: - 잔액 업데이트 (실제 데이터베이스 반영)
    private func updateBalance() {
        guard let currentUserID = parentRoomDetail?.currentUserID else { return }
        
        // 데이터베이스에서 사용자 정보 가져오기
        guard let user = CoreDataManager.shared.getUser(userID: currentUserID) else {
            print("❌ 사용자 정보를 찾을 수 없습니다")
            return
        }
        
        // 잔액 차감
        user.balance = Int32(newBalance)
        
        // 변경사항 저장
        do {
            try CoreDataManager.shared.context.save()
            print("✅ 잔액 업데이트 성공: \(previousBalance)원 → \(newBalance)원")
        } catch {
            print("❌ 잔액 업데이트 실패: \(error)")
        }
    }
    
    // MARK: - 확인 버튼 클릭
    @IBAction func checkButtonClick(_ sender: UIButton) {
        print("✅ 정산 확인 버튼 클릭")
        
        // 완료 알림 표시
        let alert = UIAlertController(
            title: "🎉 이용 완료!",
            message: "N택시를 이용해주셔서 감사합니다.\n룸 목록으로 돌아갑니다.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            // 룸 리스트 화면으로 이동 (TabBar 두 번째 탭)
            if let tabBarController = self.parentRoomDetail?.tabBarController {
                tabBarController.selectedIndex = 1 // 룸 리스트 탭
                self.parentRoomDetail?.navigationController?.popToRootViewController(animated: true)
            } else {
                self.parentRoomDetail?.navigationController?.popViewController(animated: true)
            }
            
            print("🏠 룸 리스트로 이동 완료")
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - 메모리 관리
    deinit {
        print("🗑️ StepSevenController 해제")
    }
}
