import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var currentBalance: UILabel!
    @IBOutlet weak var userSchool: UILabel!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userContainer: UIView!
    @IBOutlet weak var myBalance: UILabel!
    
    
    @IBOutlet weak var thirdView: UIView!
    @IBOutlet weak var secondView: UIView!
    @IBOutlet weak var firstView: UIView!
    
    // 사용자 정보
    var currentUserID: String!
    var currentUser: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 SettingsViewController 로드 시작")
        
        setupUI()
        loadUserInfo()
        
        print("✅ SettingsViewController 로드 완료")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 화면이 나타날 때마다 최신 잔액으로 업데이트
        updateUserBalance()
        
        print("🔄 설정 화면 나타남 - 잔액 업데이트")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 전체 배경색 설정
        view.backgroundColor = UIColor.systemGroupedBackground
        
        // 사용자 컨테이너 설정
        setupUserContainer()
        
        // 뷰 컨테이너들 설정
        setupViewContainers()
        
        // 네비게이션 설정
        navigationItem.title = "설정"
        
        print("✅ 설정 UI 설정 완료")
    }
    
    // MARK: - 뷰 컨테이너들 설정
    private func setupViewContainers() {
        // firstView 설정 (흰색 배경, 라운드)
        firstView.backgroundColor = UIColor.systemBackground
        firstView.layer.cornerRadius = 12
        firstView.layer.masksToBounds = true
        firstView.layer.borderWidth = 1
        firstView.layer.borderColor = UIColor.systemGray5.cgColor
        
        // 그림자 효과
        firstView.layer.shadowColor = UIColor.black.cgColor
        firstView.layer.shadowOffset = CGSize(width: 0, height: 2)
        firstView.layer.shadowOpacity = 0.05
        firstView.layer.shadowRadius = 4
        firstView.layer.masksToBounds = false
        
        // secondView 설정 (흰색 배경, 라운드)
        secondView.backgroundColor = UIColor.systemBackground
        secondView.layer.cornerRadius = 12
        secondView.layer.masksToBounds = true
        secondView.layer.borderWidth = 1
        secondView.layer.borderColor = UIColor.systemGray5.cgColor
        
        // 그림자 효과
        secondView.layer.shadowColor = UIColor.black.cgColor
        secondView.layer.shadowOffset = CGSize(width: 0, height: 2)
        secondView.layer.shadowOpacity = 0.05
        secondView.layer.shadowRadius = 4
        secondView.layer.masksToBounds = false
        
        // thirdView 설정 (파란색 배경, 라운드)
     
        thirdView.layer.cornerRadius = 12
        thirdView.layer.masksToBounds = true
        thirdView.layer.borderWidth = 1
        thirdView.layer.borderColor = UIColor.systemBlue.cgColor
        
        // 그림자 효과
        thirdView.layer.shadowColor = UIColor.black.cgColor
        thirdView.layer.shadowOffset = CGSize(width: 0, height: 3)
        thirdView.layer.shadowOpacity = 0.15
        thirdView.layer.shadowRadius = 6
        thirdView.layer.masksToBounds = false
        
        print("✅ 뷰 컨테이너 스타일링 완료")
    }
    
    // MARK: - 사용자 컨테이너 설정
    private func setupUserContainer() {
        userContainer.layer.cornerRadius = 12
        userContainer.backgroundColor = UIColor.systemBackground
        userContainer.layer.borderWidth = 2
        userContainer.layer.borderColor = UIColor.systemOrange.cgColor
        userContainer.layer.shadowColor = UIColor.black.cgColor
        userContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        userContainer.layer.shadowOpacity = 0.1
        userContainer.layer.shadowRadius = 4
        
        // 사용자 프로필 아이콘 추가
        let profileImageView = UIImageView()
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = UIColor.systemOrange
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        userContainer.addSubview(profileImageView)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: userContainer.topAnchor, constant: 16),
            profileImageView.centerXAnchor.constraint(equalTo: userContainer.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - 사용자 정보 로드
    private func loadUserInfo() {
        currentUserID = UserDefaults.standard.string(forKey: "currentUserID")
        
        guard let userID = currentUserID else {
            print("❌ 현재 사용자 ID가 없습니다")
            return
        }
        
        // 데이터베이스에서 사용자 정보 가져오기
        if let user = CoreDataManager.shared.getUser(userID: userID) {
            currentUser = user
            
            // UI 업데이트
            userName.text = user.name ?? "사용자"
            userName.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
            userName.textColor = UIColor.label
            
            userSchool.text = user.university ?? "대학교"
            userSchool.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            userSchool.textColor = UIColor.systemGray
            
            updateBalanceLabels(balance: Int(user.balance))
            
            print("✅ 사용자 정보 로드 완료")
            print("   - 이름: \(user.name ?? "")")
            print("   - 학교: \(user.university ?? "")")
            print("   - 잔액: \(user.balance)원")
        } else {
            print("❌ 사용자 정보를 찾을 수 없습니다")
        }
    }
    
    // MARK: - 사용자 잔액 업데이트
    private func updateUserBalance() {
        guard let userID = currentUserID,
              let user = CoreDataManager.shared.getUser(userID: userID) else { return }
        
        currentUser = user
        updateBalanceLabels(balance: Int(user.balance))
        
        print("🔄 잔액 업데이트: \(user.balance)원")
    }
    
    // MARK: - 잔액 라벨 업데이트
    private func updateBalanceLabels(balance: Int) {
        let formattedBalance = NumberFormatter.localizedString(from: NSNumber(value: balance), number: .decimal)
        
        // 현재 잔액 (큰 글씨) - thirdView가 파란색이므로 흰색 텍스트
        currentBalance.text = "\(formattedBalance)원"
        currentBalance.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        currentBalance.textColor = UIColor.blue // 🔥 파란 배경에 흰색 텍스트
        
        // 상단 잔액 (작은 글씨)
        myBalance.text = "잔액: \(formattedBalance)원"
      
         }
    
    // MARK: - 출금 버튼 클릭
    @IBAction func minusClick(_ sender: UIButton) {
        print("💳 출금 버튼 클릭")
        
        guard let user = currentUser else {
            showAlert(title: "오류", message: "사용자 정보를 불러올 수 없습니다.")
            return
        }
        
        let currentBalance = Int(user.balance)
        
        // 출금 가능한 금액이 있는지 확인
        if currentBalance <= 0 {
            showAlert(title: "출금 불가", message: "출금 가능한 잔액이 없습니다.")
            return
        }
        
        // 출금 금액 선택 액션시트
        showWithdrawActionSheet(currentBalance: currentBalance)
    }
    
    // MARK: - 충전 버튼 클릭
    @IBAction func plusClick(_ sender: UIButton) {
        print("💰 충전 버튼 클릭")
        
        // 충전 금액 선택 액션시트
        showDepositActionSheet()
    }
    
    // MARK: - 출금 금액 선택 액션시트
    private func showWithdrawActionSheet(currentBalance: Int) {
        let actionSheet = UIAlertController(
            title: "💳 출금하기",
            message: "출금할 금액을 선택해주세요\n(현재 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: currentBalance), number: .decimal))원)",
            preferredStyle: .actionSheet
        )
        
        // 출금 옵션들 (현재 잔액 내에서만)
        let withdrawOptions = [1000, 5000, 10000, 20000, 50000]
        
        for amount in withdrawOptions {
            if amount <= currentBalance {
                let action = UIAlertAction(title: "\(NumberFormatter.localizedString(from: NSNumber(value: amount), number: .decimal))원 출금", style: .default) { _ in
                    self.processWithdraw(amount: amount)
                }
                actionSheet.addAction(action)
            }
        }
        
        // 직접 입력 옵션
        let customAction = UIAlertAction(title: "직접 입력", style: .default) { _ in
            self.showCustomWithdrawAlert(maxAmount: currentBalance)
        }
        actionSheet.addAction(customAction)
        
        // 취소 버튼
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        actionSheet.addAction(cancelAction)
        
        // iPad 지원
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(actionSheet, animated: true)
    }
    
    // MARK: - 충전 금액 선택 액션시트
    private func showDepositActionSheet() {
        let actionSheet = UIAlertController(
            title: "💰 충전하기",
            message: "충전할 금액을 선택해주세요",
            preferredStyle: .actionSheet
        )
        
        // 충전 옵션들
        let depositOptions = [1000, 5000, 10000, 20000, 50000, 100000]
        
        for amount in depositOptions {
            let action = UIAlertAction(title: "\(NumberFormatter.localizedString(from: NSNumber(value: amount), number: .decimal))원 충전", style: .default) { _ in
                self.processDeposit(amount: amount)
            }
            actionSheet.addAction(action)
        }
        
        // 직접 입력 옵션
        let customAction = UIAlertAction(title: "직접 입력", style: .default) { _ in
            self.showCustomDepositAlert()
        }
        actionSheet.addAction(customAction)
        
        // 취소 버튼
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        actionSheet.addAction(cancelAction)
        
        // iPad 지원
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(actionSheet, animated: true)
    }
    
    // MARK: - 직접 출금 금액 입력
    private func showCustomWithdrawAlert(maxAmount: Int) {
        let alert = UIAlertController(
            title: "💳 출금 금액 입력",
            message: "출금할 금액을 입력해주세요\n(최대: \(NumberFormatter.localizedString(from: NSNumber(value: maxAmount), number: .decimal))원)",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "출금 금액 (원)"
            textField.keyboardType = .numberPad
        }
        
        let withdrawAction = UIAlertAction(title: "출금", style: .default) { _ in
            if let text = alert.textFields?.first?.text,
               let amount = Int(text) {
                
                if amount <= 0 {
                    self.showAlert(title: "입력 오류", message: "0원보다 큰 금액을 입력해주세요.")
                } else if amount > maxAmount {
                    self.showAlert(title: "출금 불가", message: "잔액이 부족합니다.\n(현재 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: maxAmount), number: .decimal))원)")
                } else {
                    self.processWithdraw(amount: amount)
                }
            } else {
                self.showAlert(title: "입력 오류", message: "올바른 금액을 입력해주세요.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(withdrawAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - 직접 충전 금액 입력
    private func showCustomDepositAlert() {
        let alert = UIAlertController(
            title: "💰 충전 금액 입력",
            message: "충전할 금액을 입력해주세요",
            preferredStyle: .alert
        )
        
        alert.addTextField { textField in
            textField.placeholder = "충전 금액 (원)"
            textField.keyboardType = .numberPad
        }
        
        let depositAction = UIAlertAction(title: "충전", style: .default) { _ in
            if let text = alert.textFields?.first?.text,
               let amount = Int(text) {
                
                if amount <= 0 {
                    self.showAlert(title: "입력 오류", message: "0원보다 큰 금액을 입력해주세요.")
                } else if amount > 1000000 {
                    self.showAlert(title: "충전 제한", message: "한 번에 최대 1,000,000원까지 충전 가능합니다.")
                } else {
                    self.processDeposit(amount: amount)
                }
            } else {
                self.showAlert(title: "입력 오류", message: "올바른 금액을 입력해주세요.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(depositAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - 출금 처리
    private func processWithdraw(amount: Int) {
        guard let user = currentUser,
              let userID = currentUserID else { return }
        
        let currentBalance = Int(user.balance)
        
        // 최종 잔액 확인
        if amount > currentBalance {
            showAlert(title: "출금 실패", message: "잔액이 부족합니다.")
            return
        }
        
        let newBalance = currentBalance - amount
        
        // 데이터베이스 업데이트
        user.balance = Int32(newBalance)
        
        do {
            try CoreDataManager.shared.context.save()
            
            // UI 업데이트
            updateBalanceLabels(balance: newBalance)
            
            // 성공 알림
            showSuccessAlert(
                title: "💳 출금 완료",
                message: "출금 금액: \(NumberFormatter.localizedString(from: NSNumber(value: amount), number: .decimal))원\n현재 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: newBalance), number: .decimal))원"
            )
            
            print("✅ 출금 성공: \(amount)원 (잔액: \(newBalance)원)")
            
        } catch {
            showAlert(title: "출금 실패", message: "데이터 저장 중 오류가 발생했습니다.")
            print("❌ 출금 실패: \(error)")
        }
    }
    
    // MARK: - 충전 처리
    private func processDeposit(amount: Int) {
        guard let user = currentUser,
              let userID = currentUserID else { return }
        
        let currentBalance = Int(user.balance)
        let newBalance = currentBalance + amount
        
        // 데이터베이스 업데이트
        user.balance = Int32(newBalance)
        
        do {
            try CoreDataManager.shared.context.save()
            
            // UI 업데이트
            updateBalanceLabels(balance: newBalance)
            
            // 성공 알림
            showSuccessAlert(
                title: "💰 충전 완료",
                message: "충전 금액: \(NumberFormatter.localizedString(from: NSNumber(value: amount), number: .decimal))원\n현재 잔액: \(NumberFormatter.localizedString(from: NSNumber(value: newBalance), number: .decimal))원"
            )
            
            print("✅ 충전 성공: \(amount)원 (잔액: \(newBalance)원)")
            
        } catch {
            showAlert(title: "충전 실패", message: "데이터 저장 중 오류가 발생했습니다.")
            print("❌ 충전 실패: \(error)")
        }
    }
    
    // MARK: - 알림 헬퍼 함수들
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - 메모리 관리
    deinit {
        print("🗑️ SettingsViewController 해제")
    }
}
