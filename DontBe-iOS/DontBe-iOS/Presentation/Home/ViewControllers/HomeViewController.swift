//
//  HomeViewController.swift
//  DontBe-iOS
//
//  Created by yeonsu on 1/8/24.
//

import Combine
import SafariServices
import UIKit

import SnapKit

final class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    var tabBarHeight: CGFloat = 0
    var showUploadToastView: Bool = false
    var contentId: Int = 0
    var alarmTriggerType: String = ""
    var targetMemberId: Int = 0
    var alarmTriggerdId: Int = 0
    var ghostReason: String = ""
    var hasAppearedBefore = false
    
    var transparentReasonView = DontBePopupReasonView()
    var deletePostPopupVC = DeletePopupViewController(viewModel: DeletePostViewModel(networkProvider: NetworkService()))

    let refreshControl = UIRefreshControl()

    private var cancelBag = CancelBag()
    private let homeViewModel: HomeViewModel
    let postViewModel = PostDetailViewModel(networkProvider: NetworkService())
    
    private lazy var firstReason = self.transparentReasonView.firstReasonView.radioButton.publisher(for: .touchUpInside).map { _ in }.eraseToAnyPublisher()
    private lazy var secondReason = self.transparentReasonView.secondReasonView.radioButton.publisher(for: .touchUpInside).map { _ in }.eraseToAnyPublisher()
    private lazy var thirdReason = self.transparentReasonView.thirdReasonView.radioButton.publisher(for: .touchUpInside).map { _ in }.eraseToAnyPublisher()
    private lazy var fourthReason = self.transparentReasonView.fourthReasonView.radioButton.publisher(for: .touchUpInside).map { _ in }.eraseToAnyPublisher()
    private lazy var fifthReason = self.transparentReasonView.fifthReasonView.radioButton.publisher(for: .touchUpInside).map { _ in }.eraseToAnyPublisher()
    private lazy var sixthReason = self.transparentReasonView.sixthReasonView.radioButton.publisher(for: .touchUpInside).map { _ in }.eraseToAnyPublisher()
    
    let warnUserURL = NSURL(string: "\(StringLiterals.Network.warnUserGoogleFormURL)")
    
    // MARK: - UI Components
    
    private let myView = HomeView()
    
    lazy var homeCollectionView = HomeCollectionView().collectionView
    private var deleteToastView: DontBeDeletePopupView?
    private var uploadToastView: DontBeToastView?
    private var alreadyTransparencyToastView: DontBeToastView?
    
    var deletePostBottomsheetView = DontBeBottomSheetView(singleButtonImage: ImageLiterals.Posting.btnDelete)
    var warnUserBottomsheetView = DontBeBottomSheetView(singleButtonImage: ImageLiterals.Posting.btnWarn)
    
    // MARK: - Life Cycles
    
    override func loadView() {
        super.loadView()
        
        view = myView
    }
    
    init(viewModel: HomeViewModel) {
        self.homeViewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUI()
        setHierarchy()
        setLayout()
        setDelegate()
        setAddTarget()
        setRefreshControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = false
        
        bindViewModel()
        setNotification()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
        self.navigationController?.navigationBar.backgroundColor = .clear

        NotificationCenter.default.removeObserver(self, name: DeletePopupViewController.popViewController, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("DismissDetailView"), object: nil)
    }
    
    // MARK: - TabBar Height
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let safeAreaHeight = view.safeAreaInsets.bottom
        let tabBarHeight: CGFloat = 70.0
        
        self.tabBarHeight = tabBarHeight + safeAreaHeight
    }
}

// MARK: - Extensions

extension HomeViewController {
    private func setUI() {
        self.view.backgroundColor = UIColor.donGray1
        
        deletePostPopupVC.modalPresentationStyle = .overFullScreen
    }
    
    private func setHierarchy() {
        view.addSubviews(homeCollectionView)
    }
    
    private func setLayout() {
        homeCollectionView.snp.makeConstraints {
            $0.top.equalTo(myView.safeAreaLayoutGuide.snp.top).offset(52.adjusted)
            $0.bottom.equalTo(tabBarHeight.adjusted)
            $0.width.equalToSuperview()
        }
    }
    
    private func setAddTarget() {
        deletePostBottomsheetView.deleteButton.addTarget(self, action: #selector(deletePostButtonTapped), for: .touchUpInside)
    }
    
    @objc
    func deletePostButtonTapped() {
        popDeletePostBottomsheetView()
        showDeletePostPopupView()
    }
    
    func popDeletePostBottomsheetView() {
        if UIApplication.shared.keyWindowInConnectedScenes != nil {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.deletePostBottomsheetView.dimView.alpha = 0
                if let window = UIApplication.shared.keyWindowInConnectedScenes {
                    self.deletePostBottomsheetView.bottomsheetView.frame = CGRect(x: 0, y: window.frame.height, width: self.deletePostBottomsheetView.frame.width, height: self.deletePostBottomsheetView.bottomsheetView.frame.height)
                }
            })
            deletePostBottomsheetView.dimView.removeFromSuperview()
            deletePostBottomsheetView.bottomsheetView.removeFromSuperview()
        }
    }
    
    func showDeletePostPopupView() {
        deletePostPopupVC.contentId = self.contentId
        self.present(self.deletePostPopupVC, animated: false, completion: nil)
    }
    
    @objc
    func warnUser() {
        popWarnUserBottomsheetView()
        showWarnUserSafariView()
    }
    
    func popWarnUserBottomsheetView() {
        if UIApplication.shared.keyWindowInConnectedScenes != nil {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                self.warnUserBottomsheetView.dimView.alpha = 0
                if let window = UIApplication.shared.keyWindowInConnectedScenes {
                    self.warnUserBottomsheetView.bottomsheetView.frame = CGRect(x: 0, y: window.frame.height, width: self.deletePostBottomsheetView.frame.width, height: self.warnUserBottomsheetView.bottomsheetView.frame.height)
                }
            })
            warnUserBottomsheetView.dimView.removeFromSuperview()
            warnUserBottomsheetView.bottomsheetView.removeFromSuperview()
        }
    }
    
    func showWarnUserSafariView() {
        let safariView: SFSafariViewController = SFSafariViewController(url: self.warnUserURL! as URL)
        self.present(safariView, animated: true, completion: nil)
    }
    
    @objc
    private func popViewController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setDelegate() {
        homeCollectionView.dataSource = self
        homeCollectionView.delegate = self
        transparentReasonView.delegate = self
    }
    
    private func setNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(showToast(_:)), name: WriteViewController.showWriteToastNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showDeleteToast(_:)), name: DeletePopupViewController.showDeletePostToastNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(popViewController), name: DeletePopupViewController.popViewController, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didDismissPopupNotification(_:)), name: NSNotification.Name("DismissDetailView"), object: nil)
    }
    
    @objc func didDismissPopupNotification(_ notification: Notification) {
        DispatchQueue.main.async {
            self.refreshCollectionViewDidDrag()
        }
    }
    
    private func setRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshCollectionViewDidDrag), for: .valueChanged)
        homeCollectionView.refreshControl = refreshControl
        refreshControl.backgroundColor = .donGray1
    }
    
    @objc
    func refreshCollectionViewDidDrag() {
        DispatchQueue.main.async {
            self.bindViewModel()
        }
        self.perform(#selector(self.finishedRefreshing), with: nil, afterDelay: 0.1)
    }
    
    @objc
    func finishedRefreshing() {
        refreshControl.endRefreshing()
    }
    
    @objc func showToast(_ notification: Notification) {
        if let showToast = notification.userInfo?["showToast"] as? Bool {
            if showToast == true {
                DispatchQueue.main.async {
                    self.uploadToastView = DontBeToastView()
                    
                    self.view.addSubviews(self.uploadToastView ?? DontBeToastView())
                    
                    self.uploadToastView?.snp.makeConstraints {
                        $0.leading.trailing.equalToSuperview().inset(16.adjusted)
                        $0.bottom.equalTo(self.tabBarHeight.adjusted).inset(6.adjusted)
                        $0.height.equalTo(44)
                    }
                    
                    var value: Double = 0.0
                    let duration: TimeInterval = 1.0 // 애니메이션 기간 (초 단위)
                    let increment: Double = 0.01 // 증가량
                    
                    // 0에서 1까지 1초 동안 0.01씩 증가하는 애니메이션 블록
                    UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
                        for i in 1...100 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + (duration / 100) * TimeInterval(i)) {
                                value = Double(i) * increment
                                self.uploadToastView?.circleProgressBar.value = value
                            }
                        }
                    })
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.uploadToastView?.circleProgressBar.alpha = 0
                        self.uploadToastView?.checkImageView.alpha = 1
                        self.uploadToastView?.toastLabel.text = StringLiterals.Toast.uploaded
                        self.uploadToastView?.container.backgroundColor = .donPrimary
                    }
                    
                    UIView.animate(withDuration: 1.0, delay: 2, options: .curveEaseIn) {
                        self.uploadToastView?.alpha = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.uploadToastView?.circleProgressBar.alpha = 1
                        self.uploadToastView?.checkImageView.alpha = 0
                        self.uploadToastView?.toastLabel.text = StringLiterals.Toast.uploading
                        self.uploadToastView?.container.backgroundColor = .donGray3
                        
                        NotificationCenter.default.removeObserver(self, name: WriteViewController.showWriteToastNotification, object: nil)
                    }
                }
            }
        }
    }
    
    @objc func showDeleteToast(_ notification: Notification) {
        if let showToast = notification.userInfo?["showDeleteToast"] as? Bool {
            if showToast == true {
                DispatchQueue.main.async {
                    self.deleteToastView = DontBeDeletePopupView()
                    
                    self.view.addSubviews(self.deleteToastView ?? DontBeDeletePopupView())
                    
                    self.deleteToastView?.snp.makeConstraints {
                        $0.leading.trailing.equalToSuperview().inset(24.adjusted)
                        $0.centerY.equalTo(self.view.safeAreaLayoutGuide)
                        $0.height.equalTo(75.adjusted)
                    }
                    
                    UIView.animate(withDuration: 2.0, delay: 0, options: .curveEaseIn) {
                        self.deleteToastView?.alpha = 0
                        NotificationCenter.default.removeObserver(self, name: DeletePopupViewController.showDeletePostToastNotification, object: nil)
                        NotificationCenter.default.addObserver(self, selector: #selector(self.showDeleteToast(_:)), name: DeletePopupViewController.showDeletePostToastNotification, object: nil)
                    }
                }
            }
        }
    }
    
    func showAlreadyTransparencyToast() {
        DispatchQueue.main.async {
            self.alreadyTransparencyToastView = DontBeToastView()
            self.alreadyTransparencyToastView?.toastLabel.text = StringLiterals.Toast.alreadyTransparency
            self.alreadyTransparencyToastView?.circleProgressBar.alpha = 0
            self.alreadyTransparencyToastView?.checkImageView.alpha = 1
            self.alreadyTransparencyToastView?.checkImageView.image = ImageLiterals.Home.icnNotice
            self.alreadyTransparencyToastView?.container.backgroundColor = .donPrimary
            
            self.view.addSubviews(self.alreadyTransparencyToastView ?? DontBeToastView())
            
            self.alreadyTransparencyToastView?.snp.makeConstraints {
                $0.leading.trailing.equalToSuperview().inset(16.adjusted)
                $0.bottom.equalTo(self.tabBarHeight.adjusted).inset(6.adjusted)
                $0.height.equalTo(44.adjusted)
            }
            
            UIView.animate(withDuration: 1.5, delay: 1, options: .curveEaseIn) {
                self.alreadyTransparencyToastView?.alpha = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                self.alreadyTransparencyToastView?.removeFromSuperview()
            }
        }
    }
}

// MARK: - Network

extension HomeViewController {
    private func bindViewModel() {
        let input = HomeViewModel.Input(
            viewUpdate: Just(()).eraseToAnyPublisher(),
            likeButtonTapped: nil,
            firstReasonButtonTapped: firstReason,
            secondReasonButtonTapped: secondReason,
            thirdReasonButtonTapped: thirdReason,
            fourthReasonButtonTapped: fourthReason,
            fifthReasonButtonTapped: fifthReason,
            sixthReasonButtonTapped: sixthReason)
        
        let output = homeViewModel.transform(from: input, cancelBag: cancelBag)
        
        output.getData
            .receive(on: RunLoop.main)
            .sink { _ in
                self.homeCollectionView.reloadData()
            }
            .store(in: self.cancelBag)
        
        output.clickedButtonState
            .sink { [weak self] index in
                guard let self = self else { return }
                let radioSelectedButtonImage = ImageLiterals.TransparencyInfo.btnRadioSelected
                let radioButtonImage = ImageLiterals.TransparencyInfo.btnRadio
                self.transparentReasonView.warnLabel.isHidden = true
                
                switch index {
                case 1:
                    self.transparentReasonView.firstReasonView.radioButton.setImage(radioSelectedButtonImage, for: .normal)
                    self.transparentReasonView.secondReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.thirdReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fourthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fifthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.sixthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    ghostReason = self.transparentReasonView.firstReasonView.reasonLabel.text ?? ""
                case 2:
                    self.transparentReasonView.firstReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.secondReasonView.radioButton.setImage(radioSelectedButtonImage, for: .normal)
                    self.transparentReasonView.thirdReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fourthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fifthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.sixthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    ghostReason = self.transparentReasonView.secondReasonView.reasonLabel.text ?? ""
                case 3:
                    self.transparentReasonView.firstReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.secondReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.thirdReasonView.radioButton.setImage(radioSelectedButtonImage, for: .normal)
                    self.transparentReasonView.fourthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fifthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.sixthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    ghostReason = self.transparentReasonView.thirdReasonView.reasonLabel.text ?? ""
                case 4:
                    self.transparentReasonView.firstReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.secondReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.thirdReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fourthReasonView.radioButton.setImage(radioSelectedButtonImage, for: .normal)
                    self.transparentReasonView.fifthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.sixthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    ghostReason = self.transparentReasonView.fourthReasonView.reasonLabel.text ?? ""
                case 5:
                    self.transparentReasonView.firstReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.secondReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.thirdReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fourthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fifthReasonView.radioButton.setImage(radioSelectedButtonImage, for: .normal)
                    self.transparentReasonView.sixthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    ghostReason = self.transparentReasonView.fifthReasonView.reasonLabel.text ?? ""
                case 6:
                    self.transparentReasonView.firstReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.secondReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.thirdReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fourthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.fifthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                    self.transparentReasonView.sixthReasonView.radioButton.setImage(radioSelectedButtonImage, for: .normal)
                    ghostReason = self.transparentReasonView.sixthReasonView.reasonLabel.text ?? ""
                default:
                    break
                }
            }
            .store(in: self.cancelBag)
    }
    
    private func postLikeButtonAPI(isClicked: Bool, contentId: Int) {
        // 최초 한 번만 publisher 생성
        let likeButtonTapped: AnyPublisher<(Bool, Int), Never>?  = Just(())
                .map { _ in return (!isClicked, contentId) }
                .throttle(for: .seconds(2), scheduler: DispatchQueue.main, latest: false)
                .eraseToAnyPublisher()

        let input = HomeViewModel.Input(
            viewUpdate: nil,
            likeButtonTapped: likeButtonTapped,
            firstReasonButtonTapped: firstReason,
            secondReasonButtonTapped: secondReason,
            thirdReasonButtonTapped: thirdReason,
            fourthReasonButtonTapped: fourthReason,
            fifthReasonButtonTapped: fifthReason,
            sixthReasonButtonTapped: sixthReason)

        let output = self.homeViewModel.transform(from: input, cancelBag: self.cancelBag)

        output.toggleLikeButton
            .sink { _ in }
            .store(in: self.cancelBag)
    }
}

extension HomeViewController: UICollectionViewDelegate { }

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return homeViewModel.postDatas.count
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == homeCollectionView {
            if (scrollView.contentOffset.y + scrollView.frame.size.height) >= (scrollView.contentSize.height) {
                let lastContentId = homeViewModel.postDatas.last?.contentId ?? -1
                homeViewModel.cursor = lastContentId
                bindViewModel()
                DispatchQueue.main.async {
                    self.homeCollectionView.reloadData()
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell =
        HomeCollectionViewCell.dequeueReusableCell(collectionView: collectionView, indexPath: indexPath)
        
        cell.alarmTriggerType = "contentGhost"
        cell.targetMemberId = homeViewModel.postDatas[indexPath.row].memberId
        cell.alarmTriggerdId = homeViewModel.postDatas[indexPath.row].contentId
        
        if homeViewModel.postDatas[indexPath.row].memberId == loadUserData()?.memberId {
            cell.ghostButton.isHidden = true
            cell.verticalTextBarView.isHidden = true
            self.deletePostBottomsheetView.warnButton.removeFromSuperview()
            
            cell.KebabButtonAction = {
                self.deletePostBottomsheetView.showSettings()
                self.deletePostBottomsheetView.deleteButton.addTarget(self, action: #selector(self.deletePostButtonTapped), for: .touchUpInside)
                self.contentId = self.homeViewModel.postDatas[indexPath.row].contentId
            }
            
        } else {
            cell.ghostButton.isHidden = false
            cell.verticalTextBarView.isHidden = false
            self.warnUserBottomsheetView.deleteButton.removeFromSuperview()
            
            cell.KebabButtonAction = {
                self.warnUserBottomsheetView.showSettings()
                self.warnUserBottomsheetView.warnButton.addTarget(self, action: #selector(self.warnUser), for: .touchUpInside)
            }
        }
        
        cell.LikeButtonAction = {
            if cell.isLiked == true {
                cell.likeNumLabel.text = String((Int(cell.likeNumLabel.text ?? "") ?? 0) - 1)
            } else {
                cell.likeNumLabel.text = String((Int(cell.likeNumLabel.text ?? "") ?? 0) + 1)
            }
            cell.isLiked.toggle()
            cell.likeButton.setImage(cell.isLiked ? ImageLiterals.Posting.btnFavoriteActive : ImageLiterals.Posting.btnFavoriteInActive, for: .normal)
            self.postLikeButtonAPI(isClicked: cell.isLiked, contentId: self.homeViewModel.postDatas[indexPath.row].contentId)
        }
        
        cell.ProfileButtonAction = {
            let memberId = self.homeViewModel.postDatas[indexPath.row].memberId

            if memberId == loadUserData()?.memberId ?? 0  {
                self.tabBarController?.selectedIndex = 3
                if let selectedViewController = self.tabBarController?.selectedViewController {
                    self.applyTabBarAttributes(to: selectedViewController.tabBarItem, isSelected: true)
                }
                let myViewController = self.tabBarController?.viewControllers ?? [UIViewController()]
                for (index, controller) in myViewController.enumerated() {
                    if let tabBarItem = controller.tabBarItem {
                        if index != self.tabBarController?.selectedIndex {
                            self.applyTabBarAttributes(to: tabBarItem, isSelected: false)
                        }
                    }
                }
                
            } else {
                let viewController = MyPageViewController(viewModel: MyPageViewModel(networkProvider: NetworkService()))
                viewController.memberId = memberId
                self.navigationController?.pushViewController(viewController, animated: false)
            }
        }

        cell.TransparentButtonAction = {
            self.alarmTriggerType = cell.alarmTriggerType
            self.targetMemberId = cell.targetMemberId
            self.alarmTriggerdId = cell.alarmTriggerdId
            
            if let window = UIApplication.shared.keyWindowInConnectedScenes {
                window.addSubviews(self.transparentReasonView)
                
                self.transparentReasonView.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }
                
                let radioButtonImage = ImageLiterals.TransparencyInfo.btnRadio
                
                self.transparentReasonView.firstReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                self.transparentReasonView.secondReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                self.transparentReasonView.thirdReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                self.transparentReasonView.fourthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                self.transparentReasonView.fifthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                self.transparentReasonView.sixthReasonView.radioButton.setImage(radioButtonImage, for: .normal)
                self.transparentReasonView.warnLabel.isHidden = true
                self.ghostReason = ""
            }
        }
        
        cell.nicknameLabel.text = homeViewModel.postDatas[indexPath.row].memberNickname
        cell.transparentLabel.text = "투명도 \(homeViewModel.postDatas[indexPath.row].memberGhost)%"
        cell.contentTextLabel.text = homeViewModel.postDatas[indexPath.row].contentText
        cell.likeNumLabel.text = "\(homeViewModel.postDatas[indexPath.row].likedNumber)"
        cell.commentNumLabel.text = "\(homeViewModel.postDatas[indexPath.row].commentNumber)"
        cell.timeLabel.text = "\(homeViewModel.postDatas[indexPath.row].time.formattedTime())"
        cell.profileImageView.load(url: "\(homeViewModel.postDatas[indexPath.row].memberProfileUrl)")
        cell.likeButton.setImage(homeViewModel.postDatas[indexPath.row].isLiked ? ImageLiterals.Posting.btnFavoriteActive : ImageLiterals.Posting.btnFavoriteInActive, for: .normal)
        cell.isLiked = self.homeViewModel.postDatas[indexPath.row].isLiked
        cell.likeButton.setImage(cell.isLiked ? ImageLiterals.Posting.btnFavoriteActive : ImageLiterals.Posting.btnFavoriteInActive, for: .normal)
        
        // 내가 투명도를 누른 유저인 경우 -85% 적용
        if self.homeViewModel.postDatas[indexPath.row].isGhost {
            cell.grayView.alpha = 0.85
        } else {
            let alpha = self.homeViewModel.postDatas[indexPath.row].memberGhost
            cell.grayView.alpha = CGFloat(Double(-alpha) / 100)
        }
        
        // 탈퇴한 회원 닉네임 텍스트 색상 변경, 프로필로 이동 못하도록 적용
        if self.homeViewModel.postDatas[indexPath.row].isDeleted {
            cell.nicknameLabel.textColor = .donGray12
            cell.profileImageView.isUserInteractionEnabled = false
        } else {
            cell.nicknameLabel.textColor = .donBlack
            cell.profileImageView.isUserInteractionEnabled = true
        }
        
        self.contentId = homeViewModel.postDatas[indexPath.row].contentId
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let destinationViewController = PostDetailViewController(viewModel: PostDetailViewModel(networkProvider: NetworkService()))
        destinationViewController.contentId = homeViewModel.postDatas[indexPath.row].contentId
        destinationViewController.memberId = homeViewModel.postDatas[indexPath.row].memberId
        destinationViewController.userProfileURL = homeViewModel.postDatas[indexPath.row].memberProfileUrl
        self.navigationController?.pushViewController(destinationViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footer = homeCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "HomeCollectionFooterView", for: indexPath) as? HomeCollectionFooterView else { return UICollectionReusableView() }
        return footer
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        
        return CGSize(width: UIScreen.main.bounds.width, height: 24.adjusted)
    }
}

extension HomeViewController: DontBePopupReasonDelegate {
    func reasonCancelButtonTapped() {
        transparentReasonView.removeFromSuperview()
    }
    
    func reasonConfirmButtonTapped() {
        if self.ghostReason == "" {
            self.transparentReasonView.warnLabel.isHidden = false
        } else {
            transparentReasonView.removeFromSuperview()
            
            Task {
                do {
                    if let accessToken = KeychainWrapper.loadToken(forKey: "accessToken") {
                        let result = try await self.homeViewModel.postDownTransparency(accessToken: accessToken,
                                                                                       alarmTriggerType: self.alarmTriggerType,
                                                                                       targetMemberId: self.targetMemberId,
                                                                                       alarmTriggerId: self.alarmTriggerdId,
                                                                                       ghostReason: self.ghostReason)
                        refreshCollectionViewDidDrag()
                        if result?.status == 400 {
                            // 이미 투명도를 누른 대상인 경우, 토스트 메시지 보여주기
                            showAlreadyTransparencyToast()
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}
