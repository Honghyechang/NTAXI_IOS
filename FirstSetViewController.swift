import UIKit
import MapKit
import CoreLocation

class FirstSetViewController: UIViewController {
    
    @IBOutlet weak var endLabel: UITextField! // 목적지를 설정, 사용자의 학교로 고정
    @IBOutlet weak var startLabel: UITextField! // 출발지 설정 직접 입력하거나 지도에서 클릭하는데, 그 주소가 필드에 나타나도록
    @IBOutlet weak var nextButton: UIButton! // 다음버튼을 조건에 따라 활성화 비활성화
    @IBOutlet weak var firstSetErrorMessage: UILabel! // 에러메시지를 보여주는부분
    @IBOutlet weak var mapView: MKMapView! // 지도
    
    // 부모 뷰 컨트롤러 참조
    weak var parentCreateRoom: CreateRoomViewController?
    
    // 지오코더
    let geocoder = CLGeocoder()
    
    // 현재 선택된 좌표
    var selectedCoordinate: CLLocationCoordinate2D?
    var currentUserLocation: CLLocationCoordinate2D?
    
    // 한성대학교 좌표 (홈과 동일)
    let hansungUniversityLocation = CLLocationCoordinate2D(latitude: 37.58616528349631, longitude: 127.01280516488525)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("📱 FirstSetViewController 로드 시작")
        
        setupUI()
        setupMapView()
        setupTextFields()
        
        print("✅ FirstSetViewController 로드 완료")
    }
    
    // MARK: - UI 설정 (키보드 관찰자 방식)
    private func setupUI() {
        // 목적지 고정 설정 (학교명, 수정 불가)
        endLabel.isUserInteractionEnabled = false
        endLabel.backgroundColor = UIColor.systemGray6
        endLabel.textColor = UIColor.systemGray
        endLabel.text = parentCreateRoom?.currentUserUniversity ?? "한성대학교"
        
        // 출발지 텍스트필드 활성화
        startLabel.isUserInteractionEnabled = true
        startLabel.backgroundColor = UIColor.systemBackground
        startLabel.textColor = UIColor.label
        startLabel.borderStyle = .roundedRect
        startLabel.placeholder = "지도에서 선택하거나 직접 입력"
        
        // 🔥 텍스트필드 클릭 시 빈칸으로 만들기
        startLabel.addTarget(self, action: #selector(textFieldTapped), for: .editingDidBegin)
        
        // 다음 버튼 설정
        nextButton.isEnabled = false
        nextButton.backgroundColor = UIColor.systemGray3
        nextButton.setTitle("다음", for: .normal)
        nextButton.layer.cornerRadius = 8
        
        // 🔥 버튼 우선순위 설정
        setupButtonPriority()
        
        // 에러 메시지 초기 숨김
        firstSetErrorMessage.isHidden = true
        firstSetErrorMessage.textColor = .red
        firstSetErrorMessage.numberOfLines = 0
        
        // 🔥 키보드 관찰자 설정 (제스처 대신)
        setupKeyboardObserver()
        
        print("✅ FirstSetViewController UI 설정 완료")
    }
    
    // MARK: - 🔥 버튼 클릭 우선순위 보장
    private func setupButtonPriority() {
        // 다음 버튼에 높은 우선순위 부여
        nextButton.isUserInteractionEnabled = true
        nextButton.isExclusiveTouch = true // 🔥 독점 터치 보장
        
        // 버튼 터치 이벤트 강화
        nextButton.addTarget(self, action: #selector(nextButtonTouchDown), for: .touchDown)
        
        print("🔥 버튼 우선순위 설정 완료")
    }
    
    // 🔥 버튼 터치 시작 감지 (디버깅용)
    @objc private func nextButtonTouchDown() {
        print("🟡 다음 버튼 터치 시작 감지!")
    }
    
    // MARK: - 🔥 키보드 관찰자 설정 (핵심 해결책)
    private func setupKeyboardObserver() {
        // 키보드 나타날 때
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        // 키보드 사라질 때
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        print("⌨️ 키보드 관찰자 설정 완료")
    }
    
    // 🔥 키보드 나타났을 때 - 숨김 제스처 활성화
    @objc private func keyboardWillShow() {
        print("⌨️ 키보드 나타남 - 숨김 제스처 활성화")
        addKeyboardDismissGesture()
    }
    
    // 🔥 키보드 사라졌을 때 - 숨김 제스처 제거
    @objc private func keyboardWillHide() {
        print("⌨️ 키보드 사라짐 - 숨김 제스처 제거")
        removeKeyboardDismissGesture()
    }
    
    // 🔥 키보드 숨김 제스처 추가 (키보드 있을 때만)
    private func addKeyboardDismissGesture() {
        // 기존 제스처가 있으면 제거
        removeKeyboardDismissGesture()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false // 🔥 다른 터치 이벤트 방해하지 않음
        tapGesture.delegate = self // 🔥 델리게이트 설정으로 우선순위 제어
        view.addGestureRecognizer(tapGesture)
        view.tag = 999 // 🔥 키보드 제스처 식별용 태그
        
        print("✅ 키보드 숨김 제스처 추가됨 (버튼 우선순위 보장)")
    }
    
    // 🔥 키보드 숨김 제스처 제거 (키보드 없을 때)
    private func removeKeyboardDismissGesture() {
        if let gestures = view.gestureRecognizers {
            for gesture in gestures {
                if gesture is UITapGestureRecognizer && view.tag == 999 {
                    view.removeGestureRecognizer(gesture)
                    print("🗑️ 키보드 숨김 제스처 제거됨")
                }
            }
        }
        view.tag = 0 // 태그 초기화
    }
    
    // 🔥 키보드 숨김 처리 (단순명확)
    @objc private func dismissKeyboard() {
        print("⌨️ 키보드 숨김 실행")
        view.endEditing(true)
    }
    
    deinit {
        // 관찰자 제거
        NotificationCenter.default.removeObserver(self)
        print("🗑️ 키보드 관찰자 제거")
    }
    
    // 🔥 텍스트필드 클릭 시 빈칸으로 만들기
    @objc private func textFieldTapped() {
        startLabel.text = ""
        selectedCoordinate = nil
        removeStartLocationMarker()
        checkConditions()
        print("📝 텍스트필드 초기화됨")
    }
    
    // MARK: - 맵뷰 설정 (더 확대된 상태로 시작)
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
        mapView.isUserInteractionEnabled = true
        
        print("🗺️ 맵뷰 기본 설정 완료")
        
        // 🔥 지도 탭 제스처 - 단순하고 빠르게
        setupMapTapGesture()
        
        // 🔥 한성대학교 중심으로 더 확대된 상태로 지도 표시
        let region = MKCoordinateRegion(
            center: hansungUniversityLocation,
            latitudinalMeters: 600,  // 🔥 3000 → 800으로 더 확대
            longitudinalMeters: 600  // 🔥 3000 → 800으로 더 확대
        )
        mapView.setRegion(region, animated: false)
        
        // 한성대학교 마커 추가
        addSchoolAnnotation()
        
        print("✅ 맵뷰 설정 완료 (더 확대된 상태)")
    }
    
    // 🔥 지도 탭 제스처 설정 (버튼과 충돌 방지)
    private func setupMapTapGesture() {
        // 기존 제스처 모두 제거
        if let gestures = mapView.gestureRecognizers {
            for gesture in gestures {
                if gesture is UITapGestureRecognizer {
                    mapView.removeGestureRecognizer(gesture)
                }
            }
        }
        
        // 지도 전용 탭 제스처 추가
        let mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        mapTapGesture.numberOfTapsRequired = 1
        mapTapGesture.numberOfTouchesRequired = 1
        mapTapGesture.cancelsTouchesInView = true  // 🔥 지도는 독점 처리 (지도 내에서만)
        mapTapGesture.delegate = self // 🔥 델리게이트로 세밀한 제어
        
        mapView.addGestureRecognizer(mapTapGesture)
        
        print("🔥 지도 탭 제스처 설정 완료 (버튼과 분리)")
    }
    
    // 한성대학교 마커 추가 (홈과 동일)
    private func addSchoolAnnotation() {
        let schoolAnnotation = MKPointAnnotation()
        schoolAnnotation.coordinate = hansungUniversityLocation
        schoolAnnotation.title = "한성대학교"
        schoolAnnotation.subtitle = "목적지"
        mapView.addAnnotation(schoolAnnotation)
    }
    
    // 🔥 내 위치 마커 업데이트 (홈과 동일)
    private func updateMyLocationMarker(location: CLLocationCoordinate2D) {
        // 기존 사용자 위치 마커 제거
        let userAnnotations = mapView.annotations.filter { annotation in
            return annotation is MKUserLocation || annotation.title == "내 위치"
        }
        mapView.removeAnnotations(userAnnotations)
        
        // 새로운 사용자 위치 마커 추가
        let userAnnotation = MKPointAnnotation()
        userAnnotation.coordinate = location
        userAnnotation.title = "내 위치"
        userAnnotation.subtitle = "현재 위치"
        mapView.addAnnotation(userAnnotation)
        
        print("📍 내 위치 마커 업데이트: 위도 \(location.latitude), 경도 \(location.longitude)")
    }
    
    // 이미지 리사이즈 헬퍼 함수 (홈과 동일)
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // MARK: - 텍스트필드 설정
    private func setupTextFields() {
        startLabel.delegate = self
        startLabel.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        print("✅ 텍스트필드 설정 완료")
    }
    
    // MARK: - 부모로부터 현재 위치 업데이트 받기
    func updateCurrentLocation(_ location: CLLocationCoordinate2D) {
        currentUserLocation = location
        
        // 🔥 내 위치 마커 업데이트 (홈과 동일)
        updateMyLocationMarker(location: location)
        
        print("📍 FirstSet에서 현재 위치 업데이트: \(location.latitude), \(location.longitude)")
        
        // 조건 재확인
        checkConditions()
    }
    
    // MARK: - 텍스트 입력 감지
    @objc private func textFieldDidChange(_ textField: UITextField) {
        print("📝 텍스트필드 변경 감지: \(textField.text ?? "")")
        
        if let text = textField.text, !text.isEmpty, text.count > 2 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(performAddressSearch), object: nil)
            perform(#selector(performAddressSearch), with: nil, afterDelay: 1.0)
        }
    }
    
    @objc private func performAddressSearch() {
        if let address = startLabel.text, !address.isEmpty {
            print("🔍 주소 검색 실행: \(address)")
            forwardGeocode(address: address)
        }
    }
    
    // MARK: - 지도 탭 처리 (단순하고 빠르게)
    @objc private func mapTapped(_ gesture: UITapGestureRecognizer) {
        print("🔥 지도 클릭!")
        
        if gesture.state == .ended {
            let touchPoint = gesture.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            print("📍 좌표: \(coordinate.latitude), \(coordinate.longitude)")
            
            // 🔥 즉시 처리 (순서: 좌표저장 → 마커표시 → 주소검색)
            selectedCoordinate = coordinate
            updateMarkerAndUI(coordinate: coordinate)
            
            // 🔥 키보드 숨김
            view.endEditing(true)
        }
    }
    
    // 🔥 마커와 UI 즉시 업데이트 (빠른 반응)
    private func updateMarkerAndUI(coordinate: CLLocationCoordinate2D) {
        // 1. 마커 즉시 업데이트
        removeStartLocationMarker()
        addStartLocationMarker(at: coordinate)
        
        // 2. 조건 즉시 체크
        checkConditions()
        
        // 3. 주소 검색 (백그라운드)
        searchAddress(coordinate: coordinate)
        
        print("✅ 마커 및 UI 업데이트 완료")
    }
    
    // 🔥 주소 검색 (간단하게)
    private func searchAddress(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                // 🔥 현재 좌표와 일치하는 경우에만 업데이트
                guard let self = self,
                      let currentCoordinate = self.selectedCoordinate,
                      abs(currentCoordinate.latitude - coordinate.latitude) < 0.0001 &&
                      abs(currentCoordinate.longitude - coordinate.longitude) < 0.0001 else {
                    return
                }
                
                if let placemark = placemarks?.first {
                    // 🔥 간단한 주소 구성
                    var addressParts: [String] = []
                    if let name = placemark.name { addressParts.append(name) }
                    if let locality = placemark.locality { addressParts.append(locality) }
                    
                    let address = addressParts.isEmpty ? "선택된 위치" : addressParts.joined(separator: " ")
                    
                    // 🔥 startLabel에 저장 (목적지가 아니라 출발지)
                    self.updateTextFieldSafely(address)
                    print("📝 주소 업데이트: \(address)")
                } else {
                    self.updateTextFieldSafely("선택된 위치")
                }
            }
        }
    }
    
    // MARK: - 마커 관리 (완성)
    private func removeStartLocationMarker() {
        let startMarkers = mapView.annotations.filter { annotation in
            return annotation.title == "출발지"
        }
        mapView.removeAnnotations(startMarkers)
    }
    
    private func addStartLocationMarker(at coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "출발지"
        // 🔥 subtitle 제거 (간단하게)
        mapView.addAnnotation(annotation)
        print("🚕 택시 마커 추가됨")
    }
    
    // 🔥 텍스트필드 안전 업데이트 (키보드 활성화 방지)
    private func updateTextFieldSafely(_ text: String) {
        // 🔥 키보드가 나타나지 않도록 먼저 포커스 해제
        startLabel.resignFirstResponder()
        
        // 🔥 텍스트 업데이트
        startLabel.text = text
        
        // 🔥 다시 포커스 해제 확인 (키보드 방지)
        view.endEditing(true)
        
        print("📝 텍스트필드 안전 업데이트 완료: \(text)")
    }
    
    // MARK: - 포워드 지오코딩 (주소 → 좌표) - 빠른 처리
    private func forwardGeocode(address: String) {
        print("🔍 포워드 지오코딩 시작: \(address)")
        
        // 🔥 기존 요청 취소하지 않고 새로운 요청만 추가
        geocoder.geocodeAddressString(address) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    let nsError = error as NSError
                    print("❌ 주소 검색 실패:")
                    print("   - 에러 도메인: \(nsError.domain)")
                    print("   - 에러 코드: \(nsError.code)")
                    print("   - 에러 설명: \(nsError.localizedDescription)")
                    
                    if nsError.domain == "kCLErrorDomain" && nsError.code == 8 {
                        self?.showError("네트워크 연결을 확인해주세요. 잠시 후 다시 시도해보세요.")
                    } else {
                        self?.showError("입력한 주소를 찾을 수 없습니다. 다른 방식으로 입력해보세요.")
                    }
                } else if let placemark = placemarks?.first,
                          let location = placemark.location {
                    
                    print("✅ 주소 검색 성공!")
                    print("   - 입력 주소: \(address)")
                    print("   - 찾은 주소: \(placemark.name ?? ""), \(placemark.locality ?? "")")
                    print("   - 좌표: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                    
                    let coordinate = location.coordinate
                    self?.selectedCoordinate = coordinate
                    
                    self?.removeStartLocationMarker()
                    self?.addStartLocationMarker(at: coordinate)
                    
                    let region = MKCoordinateRegion(
                        center: coordinate,
                        latitudinalMeters: 1000,
                        longitudinalMeters: 1000
                    )
                    self?.mapView.setRegion(region, animated: true)
                    
                    print("📍 지도 중심 이동 완료")
                    
                    self?.checkConditions()
                } else {
                    print("❌ 주소 검색 결과 없음")
                    self?.showError("해당 주소를 찾을 수 없습니다. 더 구체적으로 입력해주세요.")
                }
            }
        }
    }
    
    // MARK: - 조건 확인 (거리 계산 포함)
    private func checkConditions() {
        print("🔍 조건 확인 시작...")
        
        guard let selectedCoordinate = selectedCoordinate else {
            print("❌ 출발지 미설정")
            updateButtonState(enabled: false, error: "출발지를 선택해주세요")
            return
        }
        
        guard let currentUserLocation = currentUserLocation else {
            print("❌ 현재 위치 미확인")
            updateButtonState(enabled: false, error: "현재 위치를 확인하는 중입니다")
            return
        }
        
        // 🔥 거리 계산 (여기서 계산됨!)
        let startLocation = CLLocation(latitude: selectedCoordinate.latitude, longitude: selectedCoordinate.longitude)
        let userLocation = CLLocation(latitude: currentUserLocation.latitude, longitude: currentUserLocation.longitude)
        let distance = userLocation.distance(from: startLocation)
        
        print("📏 거리 계산 결과:")
        print("   - 출발지: \(selectedCoordinate.latitude), \(selectedCoordinate.longitude)")
        print("   - 현재위치: \(currentUserLocation.latitude), \(currentUserLocation.longitude)")
        print("   - 계산된 거리: \(Int(distance))m")
        
        if distance > 1000 {
            // 🔥 거리 초과
            print("❌ 거리 초과: \(Int(distance))m > 1000m")
            updateButtonState(
                enabled: false,
                error: "출발지가 현재 위치에서 1000m 이상 떨어져 있습니다 (현재 거리: \(Int(distance))m)"
            )
        } else {
            // ✅ 모든 조건 충족
            print("✅ 거리 조건 충족: \(Int(distance))m ≤ 1000m")
            updateButtonState(enabled: true, error: nil)
        }
    }
    
    private func updateButtonState(enabled: Bool, error: String?) {
        nextButton.isEnabled = enabled
        nextButton.backgroundColor = enabled ? UIColor.systemOrange : UIColor.systemGray3
        // 🔥 버튼 문구는 고정, 변경하지 않음
        
        if let errorMessage = error {
            showError(errorMessage)
        } else {
            hideError()
        }
    }
    
    private func showError(_ message: String) {
        firstSetErrorMessage.text = message
        firstSetErrorMessage.isHidden = false
    }
    
    private func hideError() {
        firstSetErrorMessage.isHidden = true
        firstSetErrorMessage.text = ""
    }
    
    // 🔥 다음 버튼 클릭 (강화된 버전)
    @IBAction func nextButtonClick(_ sender: UIButton) {
        print("🔥🔥🔥 다음 버튼 클릭 감지! 🔥🔥🔥")
        
        // 🔥 키보드 먼저 숨김
        view.endEditing(true)
        
        guard let selectedCoordinate = selectedCoordinate,
              let address = startLabel.text,
              !address.isEmpty else {
            print("❌ 필수 정보가 누락됨")
            showError("출발지를 먼저 선택해주세요")
            return
        }
        
        print("✅ 첫 번째 페이지 완료 - 부모에게 데이터 전달")
        
        // 부모에게 데이터 전달 및 페이지 전환 요청
        parentCreateRoom?.handleFirstPageComplete(
            selectedCoordinate: selectedCoordinate,
            address: address
        )
    }
}

// MARK: - UITextFieldDelegate
extension FirstSetViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == startLabel, let address = textField.text, !address.isEmpty {
            forwardGeocode(address: address)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - UIGestureRecognizerDelegate (우선순위 제어)
extension FirstSetViewController: UIGestureRecognizerDelegate {
    
    // 🔥 제스처 동시 인식 허용 제어
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false // 🔥 제스처 충돌 방지
    }
    
    // 🔥 제스처 인식 조건 설정
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        // 🔥 다음 버튼 터치 시 제스처 무시
        if touch.view == nextButton || touch.view?.isDescendant(of: nextButton) == true {
            print("🔥 버튼 클릭 감지 - 제스처 무시")
            return false
        }
        
        // 🔥 지도 제스처인 경우 - 지도 영역에서만 작동
        if gestureRecognizer.view == mapView {
            print("🗺️ 지도 제스처 허용")
            return true
        }
        
        // 🔥 키보드 숨김 제스처인 경우 - 텍스트필드가 활성화되어 있을 때만
        if gestureRecognizer.view?.tag == 999 {
            let isKeyboardVisible = startLabel.isFirstResponder
            print("⌨️ 키보드 제스처 - 키보드 상태: \(isKeyboardVisible)")
            return isKeyboardVisible
        }
        
        return true
    }
    
    // 🔥 제스처 시작 전 추가 검증
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        // 다음 버튼 영역 터치 시 제스처 차단
        let touchPoint = gestureRecognizer.location(in: view)
        let buttonFrame = nextButton.frame
        
        if buttonFrame.contains(touchPoint) {
            print("🔥 버튼 영역 터치 - 제스처 차단")
            return false
        }
        
        return true
    }
}

// MARK: - MKMapViewDelegate (홈과 동일한 방식)
extension FirstSetViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 🔥 커스텀 내 위치 마커 (홈과 동일)
        if let pointAnnotation = annotation as? MKPointAnnotation,
           pointAnnotation.title == "내 위치" {
            let identifier = "MyLocationAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                
                // mylocation 이미지를 사용해서 커스텀 사용자 위치 표시
                if let originalImage = UIImage(named: "mylocation") {
                    let newSize = CGSize(width: 20, height: 20)
                    let customImage = resizeImage(image: originalImage, targetSize: newSize)
                    
                    // 원형 배경 추가
                    let circleView = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
                    circleView.backgroundColor = UIColor.systemBlue
                    circleView.layer.cornerRadius = 12
                    circleView.layer.borderWidth = 2
                    circleView.layer.borderColor = UIColor.white.cgColor
                    
                    // 이미지뷰를 원형 배경에 추가
                    let imageView = UIImageView(image: customImage)
                    imageView.frame = CGRect(x: 2, y: 2, width: 20, height: 20)
                    imageView.tintColor = .white
                    circleView.addSubview(imageView)
                    
                    // UIView를 UIImage로 변환
                    UIGraphicsBeginImageContextWithOptions(circleView.bounds.size, false, 0)
                    circleView.layer.render(in: UIGraphicsGetCurrentContext()!)
                    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    annotationView?.image = finalImage
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        // 기존 MKUserLocation 처리 (iOS 기본 사용자 위치) - 숨김 처리
        if annotation is MKUserLocation {
            return nil // 기본 사용자 위치 마커 숨김
        }
        
        // 학교 마커 (홈과 동일)
        if annotation.title == "한성대학교" {
            let identifier = "SchoolAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // 이미지 크기 조절
                if let originalImage = UIImage(named: "school") {
                    let newSize = CGSize(width: 30, height: 30)
                    annotationView?.image = resizeImage(image: originalImage, targetSize: newSize)
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        // 출발지 마커
        if annotation.title == "출발지" {
            let identifier = "StartLocationAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                
                // 택시 이미지 사용 (홈과 동일)
                if let originalImage = UIImage(named: "taxi") {
                    let newSize = CGSize(width: 25, height: 25)
                    annotationView?.image = resizeImage(image: originalImage, targetSize: newSize)
                }
            } else {
                annotationView?.annotation = annotation
            }
            
            return annotationView
        }
        
        return nil
    }
}
