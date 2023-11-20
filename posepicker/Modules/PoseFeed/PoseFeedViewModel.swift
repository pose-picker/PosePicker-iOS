//
//  PoseFeedViewModel.swift
//  posepicker
//
//  Created by 박경준 on 2023/10/21.
//

import UIKit
import RxCocoa
import RxDataSources
import RxSwift
import Kingfisher

class PoseFeedViewModel: ViewModelType {
    
    var apiSession: APIService = APISession()
    var disposeBag = DisposeBag()
    
    var filteredContentSizes = BehaviorRelay<[CGSize]>(value: [])
    var recommendedContentsSizes = BehaviorRelay<[CGSize]>(value: [])
    
    var isLoading = false
    var currentPage = 0
    var isLast = false
    
    /// 포즈피드 컬렉션뷰 datasource 정의
    let dataSource = RxCollectionViewSectionedReloadDataSource<PoseSection>(configureCell: { dataSource, collectionView, indexPath, item in
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PoseFeedPhotoCell.identifier, for: indexPath) as? PoseFeedPhotoCell else { return UICollectionViewCell() }
        cell.bind(to: item)
        return cell
    }, configureSupplementaryView: { dataSource, collectionView, kind, indexPath -> UICollectionReusableView in
        if indexPath.section == 0 {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PoseFeedEmptyView.identifier, for: indexPath) as! PoseFeedEmptyView
            return header
        } else if indexPath.section == 1 {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PoseFeedHeader.identifier, for: indexPath) as! PoseFeedHeader
            let title = dataSource.sectionModels[indexPath.section].header
            header.configureHeader(with: title)
            return header
        } else { return UICollectionReusableView() }
    })
    
    enum CountTagType {
        case head
        case frame
    }
    
    struct Input {
        let filterButtonTapped: ControlEvent<Void> // O
        let tagItems: Observable<(PeopleCountTags, FrameCountTags, [FilterTags])> // O
        let filterTagSelection: Observable<RegisteredFilterCellViewModel> // O
        let filterRegisterCompleted: ControlEvent<Void> // O
        let poseFeedFilterViewIsPresenting: Observable<Bool> // O
        let requestAllPoseTrigger: Observable<Void>
        let poseFeedSelection: ControlEvent<PoseFeedPhotoCellViewModel>
        let nextPageRequestTrigger: Observable<Void>
        let modalDismissWithTag: Observable<String>
    }
    
    struct Output {
        let presentModal: Driver<Void> // O
        let filterTagItems: Driver<[RegisteredFilterCellViewModel]> // O
        let deleteTargetFilterTag: Driver<FilterTags?>
        let deleteTargetCountTag: Driver<CountTagType?>
        let sectionItems: Observable<[PoseSection]>
        let poseDetailViewPush: Driver<PoseDetailViewModel?>
    }
    
    // MARK: - 이미지 하나씩 바인딩하지 말고 모두 다 받고 진행
    func transform(input: Input) -> Output {
        
        let tagItems = BehaviorRelay<[RegisteredFilterCellViewModel]>(value: [])
        let deleteTargetFilterTag = BehaviorRelay<FilterTags?>(value: nil)
        
        let deleteTargetPeopleCountTag = BehaviorRelay<PeopleCountTags?>(value: nil)
        let deleteTargetFrameCountTag = BehaviorRelay<FrameCountTags?>(value: nil)
        
        let deleteTargetCountTag = BehaviorRelay<CountTagType?>(value: nil) // FIXME: 리팩토링 대상
        
        let filterSection = BehaviorRelay<[PoseFeedPhotoCellViewModel]>(value: [])
        let recommendSection = BehaviorRelay<[PoseFeedPhotoCellViewModel]>(value: [])
        let recommendContents = BehaviorRelay<RecommendedContents?>(value: nil)
        
        let sectionItems = BehaviorRelay<[PoseSection]>(value: [PoseSection(header: "", items: []), PoseSection(header: "이런 포즈는 어때요?", items: [])])
        let poseDetailViewModel = BehaviorRelay<PoseDetailViewModel?>(value: nil)
        let queryParameters = BehaviorRelay<[String]>(value: [])
        
        /// 필터 등록 완료 + 필터 모달이 Present 상태일때
        /// 인원 수 & 프레임 수 셀렉션으로부터 데이터 추출
        input.filterRegisterCompleted
            .flatMapLatest { () -> Observable<Bool> in
                return input.poseFeedFilterViewIsPresenting
            }
            .flatMapLatest { isPresenting -> Observable<(PeopleCountTags, FrameCountTags, [FilterTags])> in
                if isPresenting {
                    return Observable<(PeopleCountTags, FrameCountTags, [FilterTags])>.empty()
                } else {
                    return input.tagItems
                }
            }
            .flatMapLatest { (headcount, frameCount, filterTags) -> Observable<[String]> in
                return BehaviorRelay<[String]>(value: [headcount.rawValue, frameCount.rawValue] + filterTags.map { $0.rawValue} ).asObservable()
            }
            .subscribe(onNext: { tags in
                queryParameters.accept(tags)
                tagItems.accept(tags.compactMap { tagName in
                    if tagName == "전체" { return nil }
                    return RegisteredFilterCellViewModel(title: tagName)
                })
            })
            .disposed(by: disposeBag)
        
        /// 포즈피드 태그 modelSelected 이후 태그 삭제를 위한 단위 추출 (1컷, 1인 등)
        /// 필터태그는 그냥 삭제
        input.filterTagSelection
            .subscribe(onNext: {
                // MARK: - 상세 뷰에서 탭하여 태그가 하나만 생성된 경우
                /// 모달을 통한 필터 세팅시에는 카운트값이 프레임 & 인원 수 태그로 인해 쿼리 파라미터 갯수가 최소 2부터 시작임
                if queryParameters.value.count == 1 {
                    // 쿼리셋과 데이터는 연결해줘야함
                    let singleTag = $0
                    if let index = tagItems.value.firstIndex(where: { viewModel in
                        singleTag.title.value == viewModel.title.value
                    }) {
                        var tagItemsValue = tagItems.value
                        tagItemsValue.remove(at: index)
                        tagItems.accept(tagItemsValue)
                        queryParameters.accept(["전체", "전체"])
                        return
                    }
                }
                
                // 일반 태그인 경우
                if let filterTag = FilterTags.getTagFromTitle(title: $0.title.value) {
                    deleteTargetFilterTag.accept(filterTag)
                    return
                }
                
                // 인원 수 태그인 경우
                if let peopleCount = PeopleCountTags.getTagFromTitle(title: $0.title.value) {
                    deleteTargetPeopleCountTag.accept(peopleCount)
                    print("people!!: \(peopleCount)")
                }
                
                // 프레임 수 태그인 경우
                if let frameCount = FrameCountTags.getTagFromTitle(title: $0.title.value) {
                    deleteTargetFrameCountTag.accept(frameCount)
                    print("FRAME!!: \(frameCount)")
                }
                
                // 인원 수 및 프레임 수 태그인 경우 -> 문자열로 표기하지 말고 해당 데이터도 열거형 처리
                if !$0.title.value.isEmpty { // 인원수 or 프레임 수 태그인 경우
                    let tagName = $0.title.value
                    let tagUnit = tagName[tagName.index(tagName.startIndex, offsetBy: 1)]
                    switch tagUnit {
                    case "컷":
                        deleteTargetCountTag.accept(.frame)
                    case "인":
                        deleteTargetCountTag.accept(.head)
                    default:
                        break
                    }
                }
            })
            .disposed(by: disposeBag)
        
        /// 1. 포즈피드 초기 진입시 데이터 요청
        input.requestAllPoseTrigger
            .flatMapLatest { [unowned self] _ -> Observable<PoseFeed> in self.apiSession.requestSingle(.retrieveAllPoseFeed(pageNumber: self.currentPage, pageSize: 8)).asObservable() }
            .map { $0.content }
            .flatMapLatest { [unowned self] posefeed -> Observable<[PoseFeedPhotoCellViewModel]> in
                return self.retrieveCacheObservable(posefeed: posefeed)
            }
            .subscribe(onNext: {
                filterSection.accept($0)
            })
            .disposed(by: disposeBag)
        
        /// 2-1. 포즈피드 필터 세팅 이후 데이터 요청 (필터링 데이터 세팅)
        queryParameters
            .flatMapLatest { [unowned self] tags -> Observable<FilteredPose> in
                if tags.isEmpty { return Observable<FilteredPose>.empty() }
                
                // MARK: - 초기화 로직
                self.currentPage = 0
                self.beginLoading()
                filterSection.accept([])
                recommendSection.accept([])
                self.filteredContentSizes.accept([])
                self.recommendedContentsSizes.accept([])
                
                let filterTags: [String] = tags.count > 2 ? Array(tags[2..<tags.count]) : []
                
                // MARK: - 상세 뷰에서 셀 탭을 통해 모달로 태그 세팅되었을때
                if tags.count == 1 {
                    // 인원 수 태그일때
                    if let _ = FilterTags.getNumberFromPeopleCountString(countString: tags.first!) {
                        return self.apiSession.requestSingle(.retrieveFilteringPoseFeed(peopleCount: tags.first!, frameCount: "전체", filterTags: [], pageNumber: 0)).asObservable()
                    }
                    
                    // 프레임 수 태그일때
                    if let _ = FilterTags.getNumberFromFrameCountString(countString: tags.first!) {
                        return self.apiSession.requestSingle(.retrieveFilteringPoseFeed(peopleCount: "전체", frameCount: tags.first!, filterTags: [], pageNumber: 0)).asObservable()
                    }
                    
                    return self.apiSession.requestSingle(.retrieveFilteringPoseFeed(peopleCount: "전체", frameCount: "전체", filterTags: tags, pageNumber: 0)).asObservable()
                }
                
                return self.apiSession.requestSingle(.retrieveFilteringPoseFeed(peopleCount: tags[0], frameCount: tags[1], filterTags: filterTags, pageNumber: self.currentPage)).asObservable()
            }
            .flatMapLatest { [unowned self] filteredPose -> Observable<[PoseFeedPhotoCellViewModel]> in
                self.isLast = filteredPose.filteredContents.last // 추천섹션 데이터 accept처리
                recommendContents.accept(filteredPose.recommendedContents)
                return self.retrieveCacheObservable(posefeed: filteredPose.filteredContents.content)
            }
            .subscribe(onNext: {
                self.endLoading()
                filterSection.accept($0) // 기존 필터링 섹션 데이터 전체 초기화 후 새로 가져온 데이터로 교체
            })
            .disposed(by: disposeBag)
        
        /// 2-2. 포즈피드 필터 세팅 이후 추천 컨텐츠
        recommendContents
            .compactMap { $0 }
            .flatMapLatest { [unowned self] recommendedContents -> Observable<[PoseFeedPhotoCellViewModel]> in
                self.isLast = recommendedContents.last
                self.endLoading()
                return self.retrieveCacheObservable(posefeed: recommendedContents.content, isFilterSection: false)
            }
            .subscribe(onNext: {
                recommendSection.accept(recommendSection.value + $0)
            })
            .disposed(by: disposeBag)
        
        /// 3. 셀 탭 이후 디테일 뷰 표시를 위한 PoseDetailViewModel 뷰모델 바인딩
        input.poseFeedSelection
            .flatMapLatest { [unowned self] viewModel -> Observable<PosePick> in
                return self.apiSession.requestSingle(.retrievePoseDetail(poseId: viewModel.poseId.value)).asObservable()
            }
            .subscribe(onNext: {
                let viewModel = PoseDetailViewModel(poseDetailData: $0)
                poseDetailViewModel.accept(viewModel)
            })
            .disposed(by: disposeBag)
        
        /// 4-1. 다음 페이지 요청 트리거 - 쿼리 세팅 안된 상태 (포즈피드 초기 진입 이후의 무한스크롤)
        input.nextPageRequestTrigger
            .flatMapLatest { queryParameters }
            .flatMapLatest { [unowned self] querySet -> Observable<PoseFeed> in
                if querySet.isEmpty {
                    self.beginLoading() // 로딩 시작
                    self.currentPage += 1
                    return self.apiSession.requestSingle(.retrieveAllPoseFeed(pageNumber: self.currentPage, pageSize: 8)).asObservable()
                } else {
                    return Observable<PoseFeed>.empty()
                }
            }
            .flatMapLatest { [unowned self] posefeed -> Observable<[PoseFeedPhotoCellViewModel]> in
                self.isLast = posefeed.last
                return retrieveCacheObservable(posefeed: posefeed.content)
            }
            .subscribe(onNext: { [unowned self] in
                self.endLoading() // 로딩 끝
                filterSection.accept(filterSection.value + $0)
            })
            .disposed(by: disposeBag)
        
        /// 4-2. 다음 페이지 요청 트리거 - 쿼리 세팅 된 상태 (포즈피드 진입 후 필터 세팅된 이후의 무한스크롤)
        input.nextPageRequestTrigger
            .flatMapLatest { queryParameters }
            .flatMapLatest { [unowned self] querySet -> Observable<FilteredPose> in
                if querySet.isEmpty {
                    return Observable<FilteredPose>.empty()
                } else {
                    // 인원 수 & 프레임 수 제외한 나머지 태그들 추출하는 로직
                    let filterTags: [String] = querySet.count > 2 ? Array(querySet[2..<querySet.count]) : []
                    self.beginLoading()
                    self.currentPage += 1
                    
                    // MARK: - 상세 뷰에서 셀 탭을 통해 모달로 태그 세팅되었을때의 무한스크롤
                    if querySet.count == 1 {
                        // 인원 수 태그일때
                        if let _ = FilterTags.getNumberFromPeopleCountString(countString: querySet.first!) {
                            return self.apiSession.requestSingle(.retrieveFilteringPoseFeed(peopleCount: querySet.first!, frameCount: "전체", filterTags: [], pageNumber: self.currentPage)).asObservable()
                        }
                        
                        // 프레임 수 태그일때
                        if let _ = FilterTags.getNumberFromFrameCountString(countString: querySet.first!) {
                            return self.apiSession.requestSingle(.retrieveFilteringPoseFeed(peopleCount: "전체", frameCount: querySet.first!, filterTags: [], pageNumber: self.currentPage)).asObservable()
                        }
                        
                        return self.apiSession.requestSingle(.retrieveFilteringPoseFeed(peopleCount: "전체", frameCount: "전체", filterTags: querySet, pageNumber: self.currentPage)).asObservable()
                    }
                    
                    return self.apiSession.requestSingle(.retrieveFilteringPoseFeed(peopleCount: querySet[0], frameCount: querySet[1], filterTags: filterTags, pageNumber: self.currentPage)).asObservable()
                }
            }
            .flatMapLatest { [unowned self] filteredPose -> Observable<[PoseFeedPhotoCellViewModel]> in
                self.isLast = filteredPose.filteredContents.last
                recommendContents.accept(filteredPose.recommendedContents) // 2-2로 이동
                return retrieveCacheObservable(posefeed: filteredPose.filteredContents.content)
            }
            .subscribe(onNext: {
                self.endLoading()
                filterSection.accept(filterSection.value + $0)
            })
            .disposed(by: disposeBag)
        
        /// 5. 상세 페이지 태그 tap 이후 쿼리 파라미터 새로 세팅
        input.modalDismissWithTag
            .subscribe(onNext: {
                let viewModel = RegisteredFilterCellViewModel(title: $0)
                tagItems.accept([viewModel])
                queryParameters.accept([$0])
            })
            .disposed(by: disposeBag)
        
        /// 필터 섹션 & 추천 섹션 결합 후 셀 아이템에 바인딩
        Observable.combineLatest(filterSection, recommendSection)
            .subscribe(onNext: { filter, recommend in
                let newSectionItems = [PoseSection(header: "", items: filter), PoseSection(header: "이런 포즈는 어때요?", items: recommend)]
                sectionItems.accept(newSectionItems)
            })
            .disposed(by: disposeBag)
            
        
        return Output(presentModal: input.filterButtonTapped.asDriver(), filterTagItems: tagItems.asDriver(), deleteTargetFilterTag: deleteTargetFilterTag.asDriver(), deleteTargetCountTag: deleteTargetCountTag.asDriver(), sectionItems: sectionItems.asObservable(), poseDetailViewPush: poseDetailViewModel.asDriver())
    }
    
    /// 디자인 수치 기준으로 이미지 리사이징
    func newSizeImageWidthDownloadedResource(image: UIImage) -> UIImage {
        let targetWidth = (UIScreen.main.bounds.width - 56) / 2
        let newSizeImage = image.resize(newWidth: targetWidth)
        return newSizeImage
    }
    
    /// 로딩상태 업데이트
    func beginLoading() {
        self.isLoading = true
    }
    
    func endLoading() {
        self.isLoading = false
    }
    
    func retrieveCacheObservable(posefeed: [PosePick], isFilterSection: Bool = true) -> Observable<[PoseFeedPhotoCellViewModel]> {
        let viewModelObservable = BehaviorRelay<[PoseFeedPhotoCellViewModel]>(value: [])
        
        posefeed.forEach { posepick in
            ImageCache.default.retrieveImage(forKey: posepick.poseInfo.imageKey, options: nil) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let value):
                    if let image = value.image {
                        let newSizeImage = self.newSizeImageWidthDownloadedResource(image: image)
                        isFilterSection ? self.filteredContentSizes.accept(self.filteredContentSizes.value + [newSizeImage.size]) : self.recommendedContentsSizes.accept(self.recommendedContentsSizes.value + [newSizeImage.size])
                        
                        let viewModel = PoseFeedPhotoCellViewModel(image: newSizeImage, poseId: posepick.poseInfo.poseId)
                        viewModelObservable.accept(viewModelObservable.value + [viewModel])
                    } else {
                        guard let url = URL(string: posepick.poseInfo.imageKey) else { return }
                        KingfisherManager.shared.retrieveImage(with: url) { downloadResult in
                            switch downloadResult {
                            case .success(let downloadImage):
                                let newSizeImage = self.newSizeImageWidthDownloadedResource(image: downloadImage.image)
                                isFilterSection ? self.filteredContentSizes.accept(self.filteredContentSizes.value + [newSizeImage.size]) : self.recommendedContentsSizes.accept(self.recommendedContentsSizes.value + [newSizeImage.size])
                                
                                let viewModel = PoseFeedPhotoCellViewModel(image: newSizeImage, poseId: posepick.poseInfo.poseId)
                                viewModelObservable.accept(viewModelObservable.value + [viewModel])
                            case .failure:
                                return
                            }
                        }
                    }
                case .failure:
                    return
                }
            }
        }
        return viewModelObservable.asObservable().skip(while: { $0.count < posefeed.count })
    }
}
