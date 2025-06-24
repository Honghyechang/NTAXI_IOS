import UIKit
import CoreData
import CoreLocation  // 🔥 추가
class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Room Creation (CreateRoomViewController에서 사용)
    func createRoom(
        roomID: String,
        ownerID: String,
        startLocation: String,
        startLatitude: Double,
        startLongitude: Double,
        endLocation: String,
        endLatitude: Double,
        endLongitude: Double,
        maxMembers: Int,
        estimatedCost: Int,
        costPerPerson: Int
    ) -> Bool {
        
        // 1. Room 엔티티 생성
        let room = Room(context: context)
        room.roomID = roomID
        room.ownerID = ownerID
        room.startLocation = startLocation
        room.startLatitude = startLatitude
        room.startLongitude = startLongitude
        room.endLocation = endLocation
        room.endLatitude = endLatitude
        room.endLongitude = endLongitude
        room.currentMembers = 1 // 방장만 처음에 입장
        room.maxMembers = Int32(maxMembers)
        room.estimatedCost = Double(estimatedCost)
        room.costPerPerson = Int32(costPerPerson)
        room.status = "모집중"
        
        // 2. RoomMember 엔티티 생성 (방장을 멤버로 추가)
        let roomMember = RoomMember(context: context)
        roomMember.roomID = roomID
        roomMember.userID = ownerID
        roomMember.isReady = false // 방장도 처음에는 Ready 상태 아님
        
        // 3. 데이터 저장
        do {
            try context.save()
            print("✅ 새로운 방 생성 성공: \(roomID)")
            print("   - 방장: \(ownerID)")
            print("   - 출발지: \(startLocation)")
            print("   - 목적지: \(endLocation)")
            print("   - 최대인원: \(maxMembers)명")
            print("   - 예상비용: \(estimatedCost)원 (인당 \(costPerPerson)원)")
            return true
        } catch {
            print("❌ 방 생성 실패: \(error)")
            return false
        }
    }
    
    
    
    // CoreDataManager.swift에 추가할 메서드들

    // MARK: - Step 1 시뮬레이션을 위한 추가 메서드들

    // 방에서 나가기
    func leaveRoom(roomID: String, userID: String) -> Bool {
        // RoomMember에서 해당 멤버 제거
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "roomID == %@ AND userID == %@", roomID, userID)
        
        do {
            let members = try context.fetch(memberRequest)
            
            for member in members {
                context.delete(member)
            }
            
            // Room의 currentMembers 감소
            if let room = getRoom(roomID: roomID) {
                room.currentMembers = max(0, room.currentMembers - 1)
                
                // 방이 비어있으면 방 삭제 (선택사항)
                if room.currentMembers == 0 {
                    context.delete(room)
                    print("🗑️ 빈 방 삭제: \(roomID)")
                }
            }
            
            try context.save()
            print("✅ 방 나가기 성공: \(userID) -> \(roomID)")
            return true
            
        } catch {
            print("❌ 방 나가기 실패: \(error)")
            return false
        }
    }

    // 임의 멤버 입장 시뮬레이션 (Step 1용)
    func simulateMemberJoin(roomID: String) -> Bool {
        guard let room = getRoom(roomID: roomID) else {
            print("❌ 방을 찾을 수 없습니다: \(roomID)")
            return false
        }
        
        // 이미 정원이 찬 경우
        if room.currentMembers >= room.maxMembers {
            print("❌ 방이 이미 가득참")
            return false
        }
        
        // 현재 방에 참여하지 않은 더미 유저 중에서 랜덤 선택
        let existingMemberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        existingMemberRequest.predicate = NSPredicate(format: "roomID == %@", roomID)
        
        do {
            let existingMembers = try context.fetch(existingMemberRequest)
            let existingUserIDs = existingMembers.compactMap { $0.userID }
            
            // 전체 더미 유저 목록
            let allDummyUsers = [
                "woohyun", "sangwoo", "hyundo", "minjae", "soyeon",
                "jihoon", "yujin", "seungho", "eunbi",
                "student1", "student2", "student3"
            ]
            
            // 아직 참여하지 않은 유저들 필터링
            let availableUsers = allDummyUsers.filter { !existingUserIDs.contains($0) }
            
            guard let randomUserID = availableUsers.randomElement() else {
                print("❌ 참여 가능한 더미 유저가 없습니다")
                return false
            }
            
            // 해당 유저가 실제로 존재하는지 확인
            guard let _ = getUser(userID: randomUserID) else {
                print("❌ 더미 유저를 찾을 수 없습니다: \(randomUserID)")
                return false
            }
            
            // RoomMember 추가
            let roomMember = RoomMember(context: context)
            roomMember.roomID = roomID
            roomMember.userID = randomUserID
            roomMember.isReady = false // 처음에는 Ready 아님
            
            // Room의 currentMembers 증가
            room.currentMembers += 1
            
            // 방이 가득 찼으면 상태를 "대기중"으로 변경
            if room.currentMembers >= room.maxMembers {
                room.status = "대기중"
                print("방이 가득 참 - 상태를 '대기중'으로 변경: \(roomID)")
            }
            
            try context.save()
            print("✅ 임의 멤버 입장 성공: \(randomUserID) -> \(roomID) (현재 \(room.currentMembers)/\(room.maxMembers)명)")
            return true
            
        } catch {
            print("❌ 임의 멤버 입장 실패: \(error)")
            return false
        }
    }

    // 방장을 자동으로 Ready 상태로 설정
    func setOwnerReady(roomID: String) -> Bool {
        guard let room = getRoom(roomID: roomID),
              let ownerID = room.ownerID else {
            print("❌ 방 또는 방장 정보를 찾을 수 없습니다")
            return false
        }
        
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "roomID == %@ AND userID == %@", roomID, ownerID)
        
        do {
            let members = try context.fetch(memberRequest)
            
            if let ownerMember = members.first {
                ownerMember.isReady = true
                try context.save()
                print("✅ 방장 Ready 상태 설정 완료: \(ownerID)")
                return true
            } else {
                print("❌ 방장의 RoomMember 정보를 찾을 수 없습니다")
                return false
            }
            
        } catch {
            print("❌ 방장 Ready 설정 실패: \(error)")
            return false
        }
    }

    // 특정 사용자가 방의 방장인지 확인
    func isRoomOwner(roomID: String, userID: String) -> Bool {
        guard let room = getRoom(roomID: roomID) else {
            return false
        }
        
        return room.ownerID == userID
    }

   

    // 사용자 목록을 이름으로 가져오기 (UI 표시용)
    func getUserName(userID: String) -> String {
        if let user = getUser(userID: userID) {
            return user.name ?? userID
        }
        return userID
    }
    
    
    
    
    // MARK: - Core Data Saving support
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - User Management
    func createUser(userID: String, password: String, name: String, university: String, balance: Int32) {
        let user = User(context: context)
        user.userID = userID
        user.password = password
        user.name = name
        user.university = university
        user.balance = balance
        saveContext()
    }
    
    func getUserByID(_ userID: String) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }
    
    func validateLogin(userID: String, password: String) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@ AND password == %@", userID, password)
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Login validation error: \(error)")
            return nil
        }
    }
    
    // MARK: - Initialize Dummy Data
    func initializeDummyData() {
        // UserDefaults로 한 번만 생성되었는지 확인
        let hasInitialized = UserDefaults.standard.bool(forKey: "hasInitializedDummyData")
        
        if !hasInitialized {
            // 더 많은 더미 사용자 (hyechang은 방에 참여하지 않음)
            let dummyUsers = [
                // 테스트 계정 (방에 참여하지 않음)
                ("hyechang", "1234", "홍혜창", "한성대학교", Int32(1500)),
                
                // 한성대학교 학생들
                ("woohyun", "1234", "김우현", "한성대학교", Int32(8000)),
                ("sangwoo", "1234", "전상우", "한성대학교", Int32(18000)),
                ("hyundo", "1234", "윤현도", "한성대학교", Int32(12000)),
                ("minjae", "1234", "박민재", "한성대학교", Int32(15000)),
                ("soyeon", "1234", "이소연", "한성대학교", Int32(22000)),
                ("jihoon", "1234", "김지훈", "한성대학교", Int32(9000)),
                ("yujin", "1234", "최유진", "한성대학교", Int32(16000)),
                ("seungho", "1234", "정승호", "한성대학교", Int32(20000)),
                ("eunbi", "1234", "한은비", "한성대학교", Int32(13000)),
                
                // 다른 학교 학생들 (테스트용)
                ("student1", "1234", "김학생", "성신여대", Int32(11000)),
                ("student2", "1234", "이대학", "홍익대", Int32(14000)),
                ("student3", "1234", "박대생", "국민대", Int32(17000))
            ]
            
            for (id, pw, name, uni, balance) in dummyUsers {
                createUser(userID: id, password: pw, name: name, university: uni, balance: balance)
            }
            
            // 더미 데이터 생성 완료 표시
            UserDefaults.standard.set(true, forKey: "hasInitializedDummyData")
            UserDefaults.standard.synchronize()
            
            print("더미 사용자 데이터 생성 완료! (총 \(dummyUsers.count)명)")
        } else {
            print("더미 사용자 데이터가 이미 존재합니다.")
        }
    }
    
    // MARK: - Reset Dummy Data (개발/테스트용)
    func resetDummyData() {
        // 모든 User 데이터 삭제
        let userRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
        let deleteUserRequest = NSBatchDeleteRequest(fetchRequest: userRequest)
        
        // 모든 Room 데이터 삭제
        let roomRequest: NSFetchRequest<NSFetchRequestResult> = Room.fetchRequest()
        let deleteRoomRequest = NSBatchDeleteRequest(fetchRequest: roomRequest)
        
        // 모든 RoomMember 데이터 삭제
        let memberRequest: NSFetchRequest<NSFetchRequestResult> = RoomMember.fetchRequest()
        let deleteMemberRequest = NSBatchDeleteRequest(fetchRequest: memberRequest)
        
        do {
            try context.execute(deleteUserRequest)
            try context.execute(deleteRoomRequest)
            try context.execute(deleteMemberRequest)
            saveContext()
            
            // UserDefaults 초기화 플래그들 리셋
            UserDefaults.standard.set(false, forKey: "hasInitializedDummyData")
            UserDefaults.standard.set(false, forKey: "hasInitializedDummyRooms")
            UserDefaults.standard.synchronize()
            
            print("모든 더미 데이터 리셋 완료!")
        } catch {
            print("더미 데이터 리셋 실패: \(error)")
        }
    }
    
    // MARK: - Room Management
    // 1. getAvailableRooms 함수 수정 (기본적으로 "모집중"만 가져오기)
    func getAvailableRooms(for university: String) -> [Room] {
        let request: NSFetchRequest<Room> = Room.fetchRequest()
        
        // 같은 학교 + "모집중" 상태 방만 필터링
        request.predicate = NSPredicate(format: "endLocation == %@ AND status == %@", university, "모집중")
        request.sortDescriptors = [NSSortDescriptor(key: "roomID", ascending: true)]
        
        do {
            let rooms = try context.fetch(request)
            return rooms
        } catch {
            print("Error fetching available rooms: \(error)")
            return []
        }
    }
    
    // 2. joinRoom 함수 수정 - 상태 변경 로직 개선
    func joinRoom(roomID: String, userID: String) -> Bool {
        // 기존 검증 로직들...
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "roomID == %@ AND userID == %@", roomID, userID)
        
        do {
            let existingMembers = try context.fetch(memberRequest)
            if !existingMembers.isEmpty {
                print("이미 이 방에 입장한 사용자입니다.")
                return false
            }
        } catch {
            print("Error checking existing member: \(error)")
            return false
        }
        
        guard let room = getRoom(roomID: roomID) else {
            print("방을 찾을 수 없습니다.")
            return false
        }
        
        // 방 상태 확인 - "모집중"이 아니면 입장 불가
        if room.status != "모집중" {
            print("이 방은 더 이상 입장할 수 없습니다. (현재 상태: \(room.status ?? "알 수 없음"))")
            return false
        }
        
        if room.currentMembers >= room.maxMembers {
            print("방이 가득 찼습니다.")
            return false
        }
        
        // RoomMember 추가
        let roomMember = RoomMember(context: context)
        roomMember.roomID = roomID
        roomMember.userID = userID
        roomMember.isReady = false
        
        // Room의 currentMembers 증가
        room.currentMembers += 1
        
        // 🔥 핵심: 방이 가득 찼으면 "대기중"으로 변경
        if room.currentMembers >= room.maxMembers {
            room.status = "대기중" // 모집 완료, Ready 대기 상태
            print("방이 가득 참 - 상태를 '대기중'으로 변경: \(roomID)")
        }
        
        do {
            try context.save()
            print("방 입장 성공: \(userID) -> \(roomID) (현재 인원: \(room.currentMembers)/\(room.maxMembers))")
            return true
        } catch {
            print("Error joining room: \(error)")
            return false
        }
    }
    
    // 3. 새로 추가할 함수들
    
    // Ready 상태 토글 및 방 상태 변경
    func toggleUserReadyStatus(roomID: String, userID: String) -> Bool {
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "roomID == %@ AND userID == %@", roomID, userID)
        
        do {
            let members = try context.fetch(memberRequest)
            guard let member = members.first else {
                print("해당 방에서 사용자를 찾을 수 없습니다.")
                return false
            }
            
            // Ready 상태 토글
            member.isReady.toggle()
            print("사용자 \(userID) Ready 상태 변경: \(member.isReady)")
            
            // 🔥 핵심: 모든 멤버가 Ready인지 확인
            if areAllMembersReady(roomID: roomID) {
                if let room = getRoom(roomID: roomID) {
                    room.status = "완료" // 모든 멤버 Ready -> 집합 단계
                    print("모든 멤버가 Ready - 방 상태를 '완료'로 변경: \(roomID)")
                    
                    // 🔥 핵심: 모든 멤버의 위치 업데이트 시작
                    startLocationUpdatesForRoom(roomID: roomID)
                }
            }
            
            try context.save()
            return true
        } catch {
            print("Error toggling ready status: \(error)")
            return false
        }
    }
    
    // 이렇게 변경하세요
    func areAllMembersReady(roomID: String) -> Bool {
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "roomID == %@", roomID)
        
        do {
            let members = try context.fetch(memberRequest)
            return !members.isEmpty && members.allSatisfy { $0.isReady }
        } catch {
            print("Error checking members ready status: \(error)")
            return false
        }
    }
    
    // 🔥 핵심: 방의 모든 멤버 위치 업데이트 시작
    private func startLocationUpdatesForRoom(roomID: String) {
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "roomID == %@", roomID)
        
        do {
            let members = try context.fetch(memberRequest)
            
            for member in members {
                if let userID = member.userID,
                   let user = getUser(userID: userID) {
                    // 🔥 핵심: User의 isLocationActive를 true로 설정
                    user.isLocationActive = true
                    print("사용자 \(userID)의 위치 업데이트 시작")
                }
            }
            
            try context.save()
        } catch {
            print("Error starting location updates: \(error)")
        }
    }
    
    // 🔥 핵심: 사용자 위치 업데이트 (User 테이블에)
    func updateUserLocation(userID: String, latitude: Double, longitude: Double) -> Bool {
        guard let user = getUser(userID: userID) else {
            print("사용자를 찾을 수 없습니다: \(userID)")
            return false
        }
        
        // 위치 업데이트가 활성화된 경우에만 업데이트
        if user.isLocationActive {
            user.currentLatitude = latitude
            user.currentLongitude = longitude
           
            
            do {
                try context.save()
                print("사용자 \(userID) 위치 업데이트: (\(latitude), \(longitude))")
                return true
            } catch {
                print("Error updating user location: \(error)")
                return false
            }
        }
        
        return false
    }
    
    // 방의 모든 멤버 위치 정보 가져오기
    func getRoomMembersWithLocation(roomID: String) -> [(user: User, member: RoomMember)] {
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "roomID == %@", roomID)
        
        do {
            let members = try context.fetch(memberRequest)
            var result: [(user: User, member: RoomMember)] = []
            
            for member in members {
                if let userID = member.userID,
                   let user = getUser(userID: userID) {
                    result.append((user: user, member: member))
                }
            }
            
            return result
        } catch {
            print("Error fetching room members with location: \(error)")
            return []
        }
    }
    
    // 출발지 100m 반경 내 멤버 수 확인
    func getMembersWithinStartRadius(roomID: String, radiusMeters: Double = 100.0) -> Int {
        guard let room = getRoom(roomID: roomID) else { return 0 }
        
        let membersWithLocation = getRoomMembersWithLocation(roomID: roomID)
        let startLocation = CLLocation(latitude: room.startLatitude, longitude: room.startLongitude)
        
        var membersWithinRadius = 0
        
        for (user, _) in membersWithLocation {
            let userLocation = CLLocation(latitude: user.currentLatitude, longitude: user.currentLongitude)
            let distance = startLocation.distance(from: userLocation)
            
            if distance <= radiusMeters {
                membersWithinRadius += 1
                print("사용자 \(user.userID ?? "")는 출발지로부터 \(Int(distance))m (반경 내)")
            } else {
                print("사용자 \(user.userID ?? "")는 출발지로부터 \(Int(distance))m (반경 외)")
            }
        }
        
        return membersWithinRadius
    }
    
    // 🔥 핵심: 모든 멤버가 100m 내에 있는지 확인
    func areAllMembersWithinRadius(roomID: String, radiusMeters: Double = 100.0) -> Bool {
        guard let room = getRoom(roomID: roomID) else { return false }
        
        let membersWithLocation = getRoomMembersWithLocation(roomID: roomID)
        let totalMembers = Int(room.currentMembers)
        let membersWithinRadius = getMembersWithinStartRadius(roomID: roomID, radiusMeters: radiusMeters)
        
        return membersWithinRadius == totalMembers
    }
    
    // 🔥 핵심: 위치 업데이트 중단 (택시 호출 후)
    func stopLocationUpdatesForRoom(roomID: String) {
        let memberRequest: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        memberRequest.predicate = NSPredicate(format: "roomID == %@", roomID)
        
        do {
            let members = try context.fetch(memberRequest)
            
            for member in members {
                if let userID = member.userID,
                   let user = getUser(userID: userID) {
                    // 위치 업데이트 중단
                    user.isLocationActive = false
                    print("사용자 \(userID)의 위치 업데이트 중단")
                }
            }
            
            try context.save()
        } catch {
            print("Error stopping location updates: \(error)")
        }
    }
    
    // 특정 방 정보 가져오기
    func getRoom(roomID: String) -> Room? {
        let request: NSFetchRequest<Room> = Room.fetchRequest()
        request.predicate = NSPredicate(format: "roomID == %@", roomID)
        
        do {
            let rooms = try context.fetch(request)
            return rooms.first
        } catch {
            print("Error fetching room: \(error)")
            return nil
        }
    }
    
    // 특정 방의 멤버들 가져오기
    func getRoomMembers(roomID: String) -> [RoomMember] {
        let request: NSFetchRequest<RoomMember> = RoomMember.fetchRequest()
        request.predicate = NSPredicate(format: "roomID == %@", roomID)
        
        do {
            let members = try context.fetch(request)
            return members
        } catch {
            print("Error fetching room members: \(error)")
            return []
        }
    }
    
    // 사용자 정보 가져오기
    func getUser(userID: String) -> User? {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", userID)
        
        do {
            let users = try context.fetch(request)
            return users.first
        } catch {
            print("Error fetching user: \(error)")
            return nil
        }
    }
    
    // MARK: - 더미 방 데이터 추가 (테스트용)
    func addDummyRooms() {
        let hasInitialized = UserDefaults.standard.bool(forKey: "hasInitializedDummyRooms")
        
        if !hasInitialized {
            let dummyRoomsData = [
                        // 🔥 모집중 방들 (hyechang은 참여하지 않음)
                // 🔥 테스트 시나리오 1: 잔액 부족 (1500원 < 1200원*1.2=1440원) ❌
                         ("room001", "woohyun", ["woohyun", "sangwoo"], "한성대입구역 2번 출구", 37.5791, 127.0066, "한성대학교", 37.58616528349631, 127.01280516488525, 4, 4000, 1000, "모집중"),
                         
                         // 🔥 테스트 시나리오 2: 잔액 충분 (1500원 > 1200원*1.2=1440원) ✅
                         ("room002", "minjae", ["minjae"], "성신여대입구역 1번 출구", 37.5922, 127.0164, "한성대학교", 37.58616528349631, 127.01280516488525, 3, 3600, 1200, "모집중"),
                         
                         // 🔥 테스트 시나리오 3: 잔액 매우 부족 (1500원 < 2000원*1.2=2400원) ❌
                         ("room003", "soyeon", ["soyeon", "jihoon"], "삼선불가마 사우나", 37.5901, 127.0104, "한성대학교", 37.59018845003, 127.0104224480399, 4, 8000, 2000, "모집중"),
                         
                         // 기존 방들
                         ("room004", "seungho", ["seungho", "eunbi"], "혜화역 2번 출구", 37.5822, 127.0022, "한성대학교", 37.58616528349631, 127.01280516488525, 4, 4400, 1100, "모집중"),
                         
                         // 대기중 방들 (지도에 안 보임)
                         ("room005", "hyundo", ["hyundo", "seungho"], "한성대입구역 1번 출구", 37.5789, 127.0072, "한성대학교", 37.58616528349631, 127.01280516488525, 2, 2800, 1400, "대기중"),
                         ("room006", "sangwoo", ["sangwoo", "hyundo", "minjae", "soyeon"], "창신역 1번 출구", 37.5691, 127.0159, "한성대학교", 37.58616528349631, 127.01280516488525, 4, 5200, 1300, "대기중"),
                         
                         // 완료 방들 (지도에 안 보임)
                         ("room007", "eunbi", ["eunbi", "woohyun"], "미아역 3번 출구", 37.6133, 127.0291, "한성대학교", 37.58616528349631, 127.01280516488525, 2, 3000, 1500, "완료"),
                    
                    ]
            
            for (roomID, ownerID, members, startLoc, startLat, startLng, endLoc, endLat, endLng, maxMembers, totalCost, perCost, status) in dummyRoomsData {
                let room = Room(context: context)
                room.roomID = roomID
                room.ownerID = ownerID
                room.startLocation = startLoc
                room.startLatitude = startLat
                room.startLongitude = startLng
                room.endLocation = endLoc
                room.endLatitude = endLat
                room.endLongitude = endLng
                room.currentMembers = Int32(members.count)
                room.maxMembers = Int32(maxMembers)
                room.estimatedCost = Double(totalCost)
                room.costPerPerson = Int32(perCost)
                room.status = status
                
                for memberID in members {
                    let roomMember = RoomMember(context: context)
                    roomMember.roomID = roomID
                    roomMember.userID = memberID
                    roomMember.isReady = false
                }
            }
            
            do {
                try context.save()
                UserDefaults.standard.set(true, forKey: "hasInitializedDummyRooms")
                print("최종 더미 방 데이터 생성 완료")
            } catch {
                print("Error adding final dummy rooms: \(error)")
            }
        }
    }
}
// MARK: - Room Entity Extension
extension Room {
    var isAccessible: Bool {
        get {
            // UserInfo dictionary를 사용해서 임시 저장
            return (self.managedObjectContext?.userInfo["accessible_\(self.roomID ?? "")"] as? Bool) ?? true
        }
        set {
            self.managedObjectContext?.userInfo["accessible_\(self.roomID ?? "")"] = newValue
        }
    }
}
