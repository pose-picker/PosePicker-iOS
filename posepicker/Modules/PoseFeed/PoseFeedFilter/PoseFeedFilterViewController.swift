//
//  PoseFeedFilterViewController.swift
//  posepicker
//
//  Created by 박경준 on 2023/10/26.
//

import UIKit

class PoseFeedFilterViewController: BaseViewController {

    // MARK: - Subviews
    let closeButton = UIButton(type: .system)
        .then {
            $0.setImage(ImageLiteral.imgClose24.withRenderingMode(.alwaysOriginal), for: .normal)
        }
    
    let headCountLabel = UILabel()
        .then {
            $0.font = .pretendard(.medium, ofSize: 14)
            $0.text = "인원 수"
        }
    
    let headCountSelection = BasicSelection(buttonGroup: ["전체", "1인", "2인", "3인", "4인", "5인+"])
    
    let frameCountLabel = UILabel()
        .then {
            $0.text = "프레임 수"
            $0.font = .pretendard(.medium, ofSize: 14)
        }
    
    let frameCountSelection = BasicSelection(buttonGroup: ["전체", "1컷", "3컷", "4컷", "6컷", "8컷+"])
    
    let tagLabel = UILabel()
        .then {
            $0.font = .pretendard(.medium, ofSize: 14)
            $0.text = "태그"
        }
    
    let tagCollectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.register(PoseFeedFilterCell.self, forCellWithReuseIdentifier: PoseFeedFilterCell.identifier)
        return cv
    }()
    
    let resetButton = Button(status: .defaultStatus, isFill: false, position: .left, buttonTitle: "필터 초기화", image: ImageLiteral.imgRestart24.resize(to: CGSize(width: 20, height: 20)))
    
    let submitButton = Button(status: .defaultStatus, isFill: true, position: .none, buttonTitle: "포즈보기", image: nil)
    
    // MARK: - Properties
    
    var viewModel: PoseFeedFilterViewModel
    
    // MARK: - Initialization
    
    init(viewModel: PoseFeedFilterViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    override func render() {
        view.addSubViews([closeButton, headCountLabel, headCountSelection, frameCountLabel, frameCountSelection, tagLabel, tagCollectionView, resetButton, submitButton])
    
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.snp.top).offset(28)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        headCountLabel.snp.makeConstraints { make in
            make.top.equalTo(closeButton.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
        }
        
        headCountSelection.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(headCountLabel.snp.bottom).offset(8)
            make.height.equalTo(40)
        }
        
        frameCountLabel.snp.makeConstraints { make in
            make.top.equalTo(headCountSelection.snp.bottom).offset(20)
            make.leading.equalTo(headCountLabel)
        }
        
        frameCountSelection.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(frameCountLabel.snp.bottom).offset(8)
            make.height.equalTo(40)
        }
        
        tagLabel.snp.makeConstraints { make in
            make.top.equalTo(frameCountSelection.snp.bottom).offset(20)
            make.leading.equalTo(frameCountLabel)
        }
        
        tagCollectionView.snp.makeConstraints { make in
            make.top.equalTo(tagLabel.snp.bottom).offset(8)
            make.leading.equalTo(tagLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(72)
        }
        
        resetButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-36)
            make.height.equalTo(54)
            make.trailing.equalTo(view.snp.centerX).offset(-4)
        }
        
        submitButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-36)
            make.height.equalTo(54)
            make.leading.equalTo(view.snp.centerX).offset(4)
        }
    }
    
    override func configUI() {
        view.backgroundColor = .bgWhite
        
        closeButton.rx.tap.asDriver()
            .drive(onNext: { [unowned self] in
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    override func bindViewModel() {
        let input = PoseFeedFilterViewModel.Input(tagSelection: tagCollectionView.rx.modelSelected(PoseFeedFilterCellViewModel.self).asObservable())
        
        let output = viewModel.transform(input: input)
        
        output.tagItems
            .drive(tagCollectionView.rx.items(cellIdentifier: PoseFeedFilterCell.identifier, cellType: PoseFeedFilterCell.self)) { _, viewModel, cell in
                cell.bind(to: viewModel)
            }
            .disposed(by: disposeBag)
        
        tagCollectionView.updateCollectionViewHeight()
    }
}
