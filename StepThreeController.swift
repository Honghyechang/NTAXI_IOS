import UIKit

class StepThreeController: UIViewController {
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var lookingView: UIView!
    @IBOutlet weak var startAndEndLabel: UILabel!
    
    // 부모 뷰 컨트롤러 참조
    weak var parentRoomDetail: RoomDetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 StepThreeController 로드 시작")
        
        setupUI()
        setupAnimation()
        startSearchSimulation()
        
        print("✅ StepThreeController 로드 완료")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 출발지 → 목적지 라벨 설정
        setupStartEndLabel()
        
        // 검색 중 뷰 설정
        setupLookingView()
        
        // 인디케이터 설정
        setupIndicator()
        
        print("✅ Step 3 UI 설정 완료")
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
        startAndEndLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        startAndEndLabel.layer.cornerRadius = 8
        startAndEndLabel.layer.masksToBounds = true
        startAndEndLabel.layer.borderWidth = 1
        startAndEndLabel.layer.borderColor = UIColor.systemBlue.cgColor
    }
    
    // MARK: - 검색 중 뷰 설정
    private func setupLookingView() {
        lookingView.layer.cornerRadius = 20
        lookingView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.2)
        lookingView.layer.borderWidth = 2
        lookingView.layer.borderColor = UIColor.systemOrange.cgColor
        
        // 검색 아이콘 추가
        let searchImageView = UIImageView()
        searchImageView.image = UIImage(systemName: "magnifyingglass")
        searchImageView.tintColor = UIColor.systemOrange
        searchImageView.contentMode = .scaleAspectFit
        searchImageView.translatesAutoresizingMaskIntoConstraints = false
        
        lookingView.addSubview(searchImageView)
        
        NSLayoutConstraint.activate([
            searchImageView.centerXAnchor.constraint(equalTo: lookingView.centerXAnchor),
            searchImageView.centerYAnchor.constraint(equalTo: lookingView.centerYAnchor),
            searchImageView.widthAnchor.constraint(equalToConstant: 40),
            searchImageView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - 인디케이터 설정
    private func setupIndicator() {
        indicator.style = .large
        indicator.color = UIColor.systemBlue
        indicator.hidesWhenStopped = true
    }
    
    // MARK: - 애니메이션 설정
    private func setupAnimation() {
        // 검색 뷰 맥박 애니메이션
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.1
        pulseAnimation.duration = 1.0
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        lookingView.layer.add(pulseAnimation, forKey: "pulse")
        
        // 인디케이터 시작
        indicator.startAnimating()
    }
    
    // MARK: - 택시 검색 시뮬레이션
    private func startSearchSimulation() {
        print("🔍 택시 검색 시뮬레이션 시작")
        
        // 3-5초 후 Step 4로 자동 이동
        let randomDelay = 3.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            print("✅ 택시 검색 완료 - Step 4로 이동")
            
            // 애니메이션 정리
            self.lookingView.layer.removeAllAnimations()
            self.indicator.stopAnimating()
            
            // Step 4로 이동
            self.parentRoomDetail?.showStepFour()
        }
    }
    
    // MARK: - 메모리 관리
    deinit {
        lookingView?.layer.removeAllAnimations()
        indicator?.stopAnimating()
        print("🗑️ StepThreeController 해제")
    }
}
