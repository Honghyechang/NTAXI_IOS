import UIKit

class LoginViewController: UIViewController {
    
    private let loadingImageView = UIImageView()
    
    @IBOutlet weak var userPwd: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var userId: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 🔥 UITextFieldDelegate 설정 추가
        setupTextFields()
        
        // 로딩 이미지 설정 - 화면 전체에 비율 맞춰 채우기
        loadingImageView.image = UIImage(named: "appLoading")
        loadingImageView.contentMode = .scaleAspectFill // 비율 유지하며 화면 채우기
        loadingImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingImageView)
        
        NSLayoutConstraint.activate([
            loadingImageView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 더미 데이터 초기화 (한 번만)
        CoreDataManager.shared.initializeDummyData()
        // 더미 방 데이터 추가 (한 번만) - 새로 추가
        CoreDataManager.shared.addDummyRooms()
        // 2초 후 로딩 이미지 숨기기
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hideLoadingImage()
        }
        
        errorMessage.text=""
        //테스트
        userId.text="hyechang"
        userPwd.text="1234"
        
        // 🔥 화면 탭 제스처 추가 (화면 아무 곳이나 탭하면 키보드 내리기)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // 🔥 새로 추가: TextField 설정
    private func setupTextFields() {
        userId.delegate = self
        userPwd.delegate = self
        
        // Return Key 타입 설정
        userId.returnKeyType = .next      // 다음 필드로 이동
        userPwd.returnKeyType = .done     // 완료
        
        // 보안 입력 설정
        userPwd.isSecureTextEntry = true
    }
    
    // 🔥 새로 추가: 키보드 내리기
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    private func hideLoadingImage() {
        // 로딩 이미지 숨기기
        UIView.animate(withDuration: 0.5) {
            self.loadingImageView.alpha = 0
        } completion: { _ in
            self.loadingImageView.removeFromSuperview()
            // 여기서 원래 화면 내용 보여주기
            self.showMainContent()
        }
    }
    
    private func showMainContent() {
        // 배경색 변경
        view.backgroundColor = .white
        
        // 여기에 원래 로그인 화면 내용 추가
        // (스토리보드에서 설정한 UI들이 보이게 됨)
    }
    
    @IBAction func loginButtonClick(_ sender: UIButton) {
        // 🔥 로그인 버튼 클릭 시 키보드 내리기
        dismissKeyboard()
        
        // 입력값 검증
        guard let userID = userId.text, !userID.isEmpty,
              let password = userPwd.text, !password.isEmpty else {
            errorMessage.text = "아이디와 비밀번호를 입력해주세요."
            errorMessage.textColor = .red
            return
        }
        
        // 버튼 비활성화 (중복 클릭 방지)
        sender.isEnabled = false
        sender.setTitle("로그인 중...", for: .normal)
        
        // Core Data에서 사용자 검증
        DispatchQueue.global(qos: .background).async { [weak self] in
            if let user = CoreDataManager.shared.validateLogin(userID: userID, password: password) {
                // 로그인 성공
                DispatchQueue.main.async {
                    // 현재 사용자 정보 저장 (고정 정보)
                    UserDefaults.standard.set(user.userID, forKey: "currentUserID")
                    UserDefaults.standard.set(user.password, forKey: "currentUserPassword")
                    UserDefaults.standard.set(user.name, forKey: "currentUserName")
                    UserDefaults.standard.set(user.university, forKey: "currentUserUniversity")
                    
                    // 계좌 금액도 일단 저장 (참고용, 항상 DB에서 최신 조회할 예정)
                    UserDefaults.standard.set(user.balance, forKey: "currentUserBalance")
                    
                    UserDefaults.standard.synchronize()
                    
                    print("로그인 성공: \(user.name ?? "Unknown") (\(user.university ?? "Unknown"))")
                    print("저장된 정보 - ID: \(user.userID ?? ""), 잔액: \(user.balance)원")
                    
                    // HomeViewController로 이동
                    self?.moveToHomeScreen()
                }
            } else {
                // 로그인 실패
                DispatchQueue.main.async {
                    self?.errorMessage.text = "아이디 또는 비밀번호가 틀렸습니다."
                    self?.errorMessage.textColor = .red
                    
                    // 버튼 다시 활성화
                    sender.isEnabled = true
                    sender.setTitle("로그인", for: .normal)
                    
                    // 텍스트 필드 비우기
                    self?.userPwd.text = ""
                    self?.userId.text = ""
                    
                    print("로그인 실패: \(userID)")
                }
            }
        }
    }

    private func moveToHomeScreen() {
        // 스토리보드에서 HomeViewController 가져오기
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Tab Bar Controller로 이동 (HomeViewController가 첫 번째 탭)
        if let tabBarController = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            present(tabBarController, animated: true) {
                print("홈 화면으로 이동 완료")
            }
        } else {
            // Tab Bar Controller가 없으면 직접 HomeViewController로
            if let homeVC = storyboard.instantiateViewController(withIdentifier: "HomeViewController") as? HomeViewController {
                homeVC.modalPresentationStyle = .fullScreen
                present(homeVC, animated: true) {
                    print("홈 화면으로 직접 이동 완료")
                }
            } else {
                print("HomeViewController를 찾을 수 없습니다!")
                // 에러 메시지 표시
                errorMessage.text = "화면 전환 오류가 발생했습니다."
                errorMessage.textColor = .red
            }
        }
    }
}

// 🔥 새로 추가: UITextFieldDelegate 확장
extension LoginViewController: UITextFieldDelegate {
    
    // Return 키 눌렀을 때 동작
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == userId {
            // 아이디 필드에서 Return → 비밀번호 필드로 이동
            userPwd.becomeFirstResponder()
        } else if textField == userPwd {
            // 비밀번호 필드에서 Return → 키보드 내리기 + 로그인 실행
            textField.resignFirstResponder()
            
            // 로그인 버튼 자동 클릭 (선택사항)
            if let loginButton = view.subviews.first(where: { $0 is UIButton }) as? UIButton {
                loginButtonClick(loginButton)
            }
        }
        return true
    }
    
    // 편집 시작할 때 에러 메시지 지우기
    func textFieldDidBeginEditing(_ textField: UITextField) {
        errorMessage.text = ""
    }
}
