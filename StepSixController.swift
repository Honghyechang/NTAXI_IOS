import UIKit

class StepSixController: UIViewController {
    
    @IBOutlet weak var movingView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var startAndEndLabel: UILabel!
    
    // 부모 뷰 컨트롤러 참조
    weak var parentRoomDetail: RoomDetailViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 StepSixController 로드 시작")
        
        setupUI()
        setupAnimation()
        startMovingSimulation()
        
        print("✅ StepSixController 로드 완료")
    }
    
    // MARK: - UI 설정
    private func setupUI() {
        // 출발지 → 목적지 라벨 설정
        setupStartEndLabel()
        
        // 이동 중 뷰 설정
        setupMovingView()
        
        // 인디케이터 설정
        setupIndicator()
        
        print("✅ Step 6 UI 설정 완료")
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
        startAndEndLabel.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.1)
        startAndEndLabel.layer.cornerRadius = 8
        startAndEndLabel.layer.masksToBounds = true
        startAndEndLabel.layer.borderWidth = 1
        startAndEndLabel.layer.borderColor = UIColor.systemIndigo.cgColor
    }
    
    // MARK: - 이동 중 뷰 설정
    private func setupMovingView() {
        movingView.layer.cornerRadius = 12
        movingView.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.2)
        movingView.layer.borderWidth = 2
        movingView.layer.borderColor = UIColor.systemIndigo.cgColor
        
        // 이동 아이콘 추가
        let movingImageView = UIImageView()
        movingImageView.image = UIImage(systemName: "car.fill")
        movingImageView.tintColor = UIColor.systemIndigo
        movingImageView.contentMode = .scaleAspectFit
        movingImageView.translatesAutoresizingMaskIntoConstraints = false
        
        movingView.addSubview(movingImageView)
        
        NSLayoutConstraint.activate([
            movingImageView.centerXAnchor.constraint(equalTo: movingView.centerXAnchor),
            movingImageView.centerYAnchor.constraint(equalTo: movingView.centerYAnchor),
            movingImageView.widthAnchor.constraint(equalToConstant: 60),
            movingImageView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // 이동 중 텍스트 추가
        let movingLabel = UILabel()
        movingLabel.text = "목적지까지 이동 중..."
        movingLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        movingLabel.textColor = UIColor.systemIndigo
        movingLabel.textAlignment = .center
        movingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        movingView.addSubview(movingLabel)
        
        NSLayoutConstraint.activate([
            movingLabel.topAnchor.constraint(equalTo: movingImageView.bottomAnchor, constant: 8),
            movingLabel.centerXAnchor.constraint(equalTo: movingView.centerXAnchor),
            movingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: movingView.leadingAnchor, constant: 8),
            movingLabel.trailingAnchor.constraint(lessThanOrEqualTo: movingView.trailingAnchor, constant: -8)
        ])
    }
    
    // MARK: - 인디케이터 설정
    private func setupIndicator() {
        indicator.style = .large
        indicator.color = UIColor.systemIndigo
        indicator.hidesWhenStopped = true
    }
    
    // MARK: - 애니메이션 설정
    private func setupAnimation() {
        // 이동 뷰 좌우 이동 애니메이션
        let moveAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        moveAnimation.fromValue = -10
        moveAnimation.toValue = 10
        moveAnimation.duration = 1.5
        moveAnimation.autoreverses = true
        moveAnimation.repeatCount = .infinity
        moveAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        movingView.layer.add(moveAnimation, forKey: "move")
        
        // 인디케이터 시작
        indicator.startAnimating()
    }
    
    // MARK: - 이동 시뮬레이션
    private func startMovingSimulation() {
        print("🚗 택시 이동 시뮬레이션 시작")
        
        // 5-8초 후 Step 7로 자동 이동
        let randomDelay = 3.0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            print("✅ 목적지 도착 - Step 7로 이동")
            
            // 애니메이션 정리
            self.movingView.layer.removeAllAnimations()
            self.indicator.stopAnimating()
            
            // Step 7로 이동
            self.parentRoomDetail?.showStepSeven()
        }
    }
    
    // MARK: - 메모리 관리
    deinit {
        movingView?.layer.removeAllAnimations()
        indicator?.stopAnimating()
        print("🗑️ StepSixController 해제")
    }
}
