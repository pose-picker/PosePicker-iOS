//
//  PoseTalkViewController.swift
//  posepicker
//
//  Created by 박경준 on 2023/10/21.
//

import UIKit

import Lottie

class PoseTalkViewController: BaseViewController {
    
    // MARK: - Subviews
    
    let informationLabel = UILabel()
        .then {
            $0.textColor = .mainViolet
            $0.font = .h3
            $0.text = "뽑은 제시어"
        }
    
    let informationImageView = UIImageView(image: ImageLiteral.imgInfo24.withRenderingMode(.alwaysOriginal))
    
    let mainLabel = UILabel()
        .then {
            $0.numberOfLines = 0
            $0.font = .h1
            $0.text = "제시어에 맞춰\n포즈를 취해요!"
        }
    
    var animationView: LottieAnimationView = .init(name: "lottiePoseTalk")
        .then {
            $0.loopMode = .loop
            $0.play()
        }
    
    let selectButton = Button(status: .defaultStatus, isFill: true, position: .none, buttonTitle: "제시어 뽑기", image: nil)
    
    // MARK: - Properties
    
    let viewModel: PoseTalkViewModel
    
    // MARK: - Life Cycles
    
    init(viewModel: PoseTalkViewModel) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Functions
    
    override func render() {
        view.addSubViews([informationLabel, informationImageView, mainLabel, animationView, selectButton])
        
        informationLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(UIScreen.main.isWiderThan375pt ? 64 : 40)
            make.centerX.equalToSuperview().offset(-informationImageView.frame.width)
        }
        
        informationImageView.snp.makeConstraints { make in
            make.centerY.equalTo(informationLabel)
            make.leading.equalTo(informationLabel.snp.trailing)
        }
        
        mainLabel.snp.makeConstraints { make in
            make.top.equalTo(informationLabel.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
        
        animationView.snp.makeConstraints { make in
            make.top.equalTo(mainLabel.snp.bottom).offset( UIScreen.main.isWiderThan375pt ? 16 : 0)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(UIScreen.main.isWiderThan375pt ? 0 : 40)
        }
        
        selectButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }
    }
    
    override func configUI() {
        self.navigationController?.isNavigationBarHidden = true
        view.backgroundColor = .bgWhite
    }
    
    override func bindViewModel() {
        let input = PoseTalkViewModel.Input(poseTalkButtonTapped: selectButton.rx.controlEvent(.touchUpInside))
        
        let output = viewModel.transform(input: input)
        
        output.animate
            .drive(onNext: { [unowned self] in
                self.animationView.pause()
                self.animationView.loopMode = .playOnce
                self.animationView.animation = LottieAnimation.named("lottiePoseTalkTap")
                self.animationView.play()
            })
            .disposed(by: disposeBag)
    }
}