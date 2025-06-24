import UIKit

class StepFiveController: UIViewController {
    
    @IBOutlet weak var taxiDriverView: UIView!
    @IBOutlet weak var startAndEndLabel: UILabel!
    
    // 부모 뷰 컨트롤러 참조
    weak var parentRoomDetail: RoomDetailViewController?
    
    @IBOutlet weak var startButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 StepFiveController 로드 시작")
        
        setupUI()
        
        print("✅ StepFiveController 로드 완료")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 출발지 → 목적지 라벨 설정
        setupStartEndLabel()
        
        // 택시 기사 뷰 설정
        setupTaxiDriverView()
        
        // 시작 버튼 설정
        setupStartButton()
        
        print("✅ Step 5 UI 설정 완료")
    }
    
    // MARK: - 출발지 목적지 라벨 설정
    private func setupStartEndLabel() {
        guard let room = parentRoomDetail?.currentRoom else { return }
        
        let startLocation = room.startLocation ?? "출발지"
        let endLocation = room.endLocation ?? "목적지"
        
        startAndEndLabel.text = "\(startLocation) → \(endLocation)"
        startAndEndLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        startAndEndLabel.textColor = UIColor.label
        startAndEndLabel.textAlignment = .center
        startAndEndLabel.numberOfLines = 0
        
        // 배경 스타일링
        startAndEndLabel.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.1)
        startAndEndLabel.layer.cornerRadius = 8
        startAndEndLabel.layer.masksToBounds = true
        startAndEndLabel.layer.borderWidth = 1
        startAndEndLabel.layer.borderColor = UIColor.systemGreen.cgColor
    }
    
    // MARK: - 택시 기사 뷰 설정
    private func setupTaxiDriverView() {
        taxiDriverView.layer.cornerRadius = 12
        taxiDriverView.backgroundColor = UIColor.systemBackground
        taxiDriverView.layer.borderWidth = 2
        taxiDriverView.layer.borderColor = UIColor.systemGreen.cgColor
        taxiDriverView.layer.shadowColor = UIColor.black.cgColor
        taxiDriverView.layer.shadowOffset = CGSize(width: 0, height: 2)
        taxiDriverView.layer.shadowOpacity = 0.1
        taxiDriverView.layer.shadowRadius = 4
        
        // 기사 프로필 이미지 추가
        let profileImageView = UIImageView()
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        profileImageView.tintColor = UIColor.systemGreen
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        
        taxiDriverView.addSubview(profileImageView)
        
        NSLayoutConstraint.activate([
            profileImageView.topAnchor.constraint(equalTo: taxiDriverView.topAnchor, constant: 16),
            profileImageView.centerXAnchor.constraint(equalTo: taxiDriverView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
   
    
    // MARK: - 시작 버튼 설정
    private func setupStartButton() {
        startButton.layer.cornerRadius = 12
        startButton.backgroundColor = UIColor.systemGreen
        startButton.setTitle("탑승 시작", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        
        // 그림자 효과
        startButton.layer.shadowColor = UIColor.black.cgColor
        startButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        startButton.layer.shadowOpacity = 0.2
        startButton.layer.shadowRadius = 4
    }
    
    // MARK: - 탑승 시작 버튼 클릭
    @IBAction func startButtonClick(_ sender: UIButton) {
        print("🚕 탑승 시작 버튼 클릭")
        
        // Step 6으로 이동
        parentRoomDetail?.showStepSix()
    }
    
    // MARK: - 메모리 관리
    deinit {
        print("🗑️ StepFiveController 해제")
    }
}
