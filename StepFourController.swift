import UIKit

class StepFourController: UIViewController {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var matchingView: UIView!
    @IBOutlet weak var startAndEndLabel: UILabel!
    
    // 부모 뷰 컨트롤러 참조
    weak var parentRoomDetail: RoomDetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 StepFourController 로드 시작")
        
        setupUI()
        setupAnimation()
        startMatchingSimulation()
        
        print("✅ StepFourController 로드 완료")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 출발지 → 목적지 라벨 설정
        setupStartEndLabel()
        
        // 매칭 중 뷰 설정
        setupMatchingView()
        
        // 인디케이터 설정
        setupIndicator()
        
        print("✅ Step 4 UI 설정 완료")
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
        startAndEndLabel.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        startAndEndLabel.layer.cornerRadius = 8
        startAndEndLabel.layer.masksToBounds = true
        startAndEndLabel.layer.borderWidth = 1
        startAndEndLabel.layer.borderColor = UIColor.systemPurple.cgColor
    }
    
    // MARK: - 매칭 뷰 설정
    private func setupMatchingView() {
        // 원형 모양으로 설정
        matchingView.layer.cornerRadius = matchingView.frame.width / 2
        matchingView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.2)
        matchingView.layer.borderWidth = 3
        matchingView.layer.borderColor = UIColor.systemPurple.cgColor
        
        // layoutSubviews에서 다시 설정할 수 있도록 태그 추가
        matchingView.tag = 1000
        
        // 매칭 아이콘 추가
        let matchingImageView = UIImageView()
        matchingImageView.image = UIImage(systemName: "person.2.fill")
        matchingImageView.tintColor = UIColor.systemPurple
        matchingImageView.contentMode = .scaleAspectFit
        matchingImageView.translatesAutoresizingMaskIntoConstraints = false
        
        matchingView.addSubview(matchingImageView)
        
        NSLayoutConstraint.activate([
            matchingImageView.centerXAnchor.constraint(equalTo: matchingView.centerXAnchor),
            matchingImageView.centerYAnchor.constraint(equalTo: matchingView.centerYAnchor),
            matchingImageView.widthAnchor.constraint(equalToConstant: 50),
            matchingImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    // MARK: - 뷰 레이아웃 완료 후 원형 설정
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 원형으로 다시 설정 (실제 크기 확정 후)
        if matchingView.tag == 1000 {
            let size = min(matchingView.frame.width, matchingView.frame.height)
            matchingView.layer.cornerRadius = size / 2
        }
    }
    
    // MARK: - 인디케이터 설정
    private func setupIndicator() {
        indicator.style = .large
        indicator.color = UIColor.systemPurple
        indicator.hidesWhenStopped = true
    }
    
    // MARK: - 애니메이션 설정
    private func setupAnimation() {
        // 매칭 뷰 회전 애니메이션
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0
        rotationAnimation.toValue = Double.pi * 2
        rotationAnimation.duration = 2.0
        rotationAnimation.repeatCount = .infinity
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        matchingView.layer.add(rotationAnimation, forKey: "rotation")
        
        // 인디케이터 시작
        indicator.startAnimating()
    }
    
    // MARK: - 기사님 매칭 시뮬레이션
    private func startMatchingSimulation() {
        print("👥 기사님 매칭 시뮬레이션 시작")
        
        // 3-5초 후 Step 5로 자동 이동
        let randomDelay = 2.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            print("✅ 기사님 매칭 완료 - Step 5로 이동")
            
            // 애니메이션 정리
            self.matchingView.layer.removeAllAnimations()
            self.indicator.stopAnimating()
            
            // Step 5로 이동
            self.parentRoomDetail?.showStepFive()
        }
    }
    
    // MARK: - 메모리 관리
    deinit {
        matchingView?.layer.removeAllAnimations()
        indicator?.stopAnimating()
        print("🗑️ StepFourController 해제")
    }
}
