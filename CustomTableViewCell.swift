import UIKit

class CustomTableViewCell: UITableViewCell {
    @IBOutlet weak var startAndEndLabel: UILabel!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var costfix: UILabel!
    @IBOutlet weak var startfix: UILabel!
    @IBOutlet weak var memberfix: UILabel!
    @IBOutlet weak var endfix: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var costInfo: UILabel!
    @IBOutlet weak var memberInfo: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var enterClick: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupCellDesign()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // 선택 시 배경색 변경 방지
    }
    
    private func setupCellDesign() {
        // 🎨 메인 컨테이너 스타일링
        setupMainContainer()
        
        // 🏷️ 출발지→목적지 라벨 스타일링
        setupStartEndLabel()
        
        // 🔤 고정 라벨들 스타일링
        setupFixedLabels()
        
        // 📊 정보 라벨들 스타일링
        setupInfoLabels()
        
        // 🚨 에러 메시지 스타일링
        setupErrorMessage()
        
        // 🔘 입장 버튼 스타일링
        setupEnterButton()
        
        // 📱 전체 셀 스타일링
        setupCellStyle()
    }
    
    // MARK: - 메인 컨테이너 스타일링
    private func setupMainContainer() {
        container.layer.cornerRadius = 16
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOffset = CGSize(width: 0, height: 4)
        container.layer.shadowOpacity = 0.08
        container.layer.shadowRadius = 12
        
        // 🔥 컨테이너 배경색 - 연한 회색으로 변경 (카드 느낌)
        container.backgroundColor = UIColor.systemGray6
        
        // 그림자가 잘리지 않도록 설정
        container.layer.masksToBounds = false
        
        // 경계선 추가 (미묘한 효과)
        container.layer.borderWidth = 0.5
        container.layer.borderColor = UIColor.systemGray4.cgColor
    }
    
    // MARK: - 출발지→목적지 라벨 스타일링
    private func setupStartEndLabel() {
        // 🔥 크기 줄이기: 폰트 크기를 16 → 14로, 높이도 줄임
        startAndEndLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        startAndEndLabel.textColor = UIColor.label
        startAndEndLabel.numberOfLines = 1
        
        
        
        // 🔥 스토리보드에서 높이 제약조건을 28-32px로 줄이세요!
    }
    
    // MARK: - 고정 라벨들 스타일링
    private func setupFixedLabels() {
        let fixedLabels = [startfix, endfix, memberfix, costfix]
        
        for label in fixedLabels {
            label?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            label?.textColor = UIColor.systemGray
        }
    }
    
    // MARK: - 정보 라벨들 스타일링
    private func setupInfoLabels() {
        // 출발지/목적지 라벨
        let locationLabels = [startLabel, endLabel]
        for label in locationLabels {
            label?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            label?.textColor = UIColor.label
            label?.numberOfLines = 1
        }
        
        // 인원 정보 라벨
        memberInfo.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        memberInfo.textColor = UIColor.systemBlue
        
        // 🔥 비용 정보 라벨 - 크기 줄이기
        costInfo.font = UIFont.systemFont(ofSize: 12, weight: .semibold)  // 14 → 12
        costInfo.textColor = UIColor.systemOrange
        costInfo.numberOfLines = 2
        costInfo.adjustsFontSizeToFitWidth = true  // 자동 크기 조절
        costInfo.minimumScaleFactor = 0.8  // 최소 80%까지 축소 가능
    }
    
    // MARK: - 에러 메시지 스타일링
    private func setupErrorMessage() {
        // 🔥 에러 메시지 크기 줄이기
        errorMessage.font = UIFont.systemFont(ofSize: 8, weight: .medium)  // 12 → 10
        errorMessage.textColor = UIColor.systemRed
        errorMessage.numberOfLines = 2
        errorMessage.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        errorMessage.layer.cornerRadius = 4  // 6 → 4로 줄임
        errorMessage.layer.masksToBounds = true
        errorMessage.textAlignment = .center
        errorMessage.adjustsFontSizeToFitWidth = true  // 자동 크기 조절
        errorMessage.minimumScaleFactor = 0.7  // 최소 70%까지 축소 가능
        
        // 기본적으로 숨김
        errorMessage.isHidden = true
    }
    
    // MARK: - 입장 버튼 스타일링
    private func setupEnterButton() {
        enterClick.layer.cornerRadius = 12
        enterClick.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        
        // 그림자 효과
        enterClick.layer.shadowColor = UIColor.black.cgColor
        enterClick.layer.shadowOffset = CGSize(width: 0, height: 2)
        enterClick.layer.shadowOpacity = 0.1
        enterClick.layer.shadowRadius = 4
        
        // 기본 활성화 상태 스타일
        setActiveButtonStyle()
    }
    
    // MARK: - 전체 셀 스타일링
    private func setupCellStyle() {
        // 셀 선택 시 배경색 변경 방지
        selectionStyle = .none
        
        // 🔥 셀 배경색 - 흰색으로 변경
        backgroundColor = UIColor.white
        
        // 🔥 스토리보드에서 container의 상하좌우 마진을 8-12px로 설정하세요!
    }
    
    // MARK: - 버튼 상태별 스타일 함수들
    func setActiveButtonStyle() {
        enterClick.backgroundColor = UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0) // #FF9500
        enterClick.setTitleColor(.white, for: .normal)
        enterClick.layer.shadowOpacity = 0.1
        
        // 호버 효과 (터치 시)
        enterClick.setTitleColor(UIColor.white.withAlphaComponent(0.8), for: .highlighted)
    }
    
    func setInactiveButtonStyle(title: String, backgroundColor: UIColor) {
        enterClick.backgroundColor = backgroundColor
        enterClick.setTitle(title, for: .normal)
        enterClick.setTitleColor(.white, for: .normal)
        enterClick.layer.shadowOpacity = 0.05
    }
    
    // MARK: - 애니메이션 효과 (선택사항)
    func animatePress() {
        UIView.animate(withDuration: 0.1, animations: {
            self.container.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.container.transform = CGAffineTransform.identity
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // 재사용 시 초기화
        errorMessage.isHidden = true
        setActiveButtonStyle()
        container.transform = CGAffineTransform.identity
    }
}
