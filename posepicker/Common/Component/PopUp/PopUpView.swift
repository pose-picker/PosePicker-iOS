//
//  PopUpView.swift
//  posepicker
//
//  Created by 박경준 on 2023/11/16.
//

import UIKit
import RxCocoa
import RxSwift

class PopUpView: UIView {

    // MARK: - Subviews
    let box = UIView()
        .then {
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 16
            $0.backgroundColor = .bgWhite
        }
    
    let alertLabel = UILabel()
        .then {
            $0.font = .pretendard(.regular, ofSize: 16)
        }
    
    let completeButton = PosePickButton(status: .defaultStatus, isFill: true, position: .none, buttonTitle: "확인", image: nil)
    
    let cancelButton = UIButton(type: .system)
        .then {
            $0.setTitle("취소", for: .normal)
            $0.setTitleColor(.textSecondary, for: .normal)
            $0.titleLabel?.font = .pretendard(.medium, ofSize: 16)
            $0.backgroundColor = .bgSubWhite
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 12
        }
    
    let confirmButton = UIButton(type: .system)
        .then {
            $0.setTitle("확인", for: .normal)
            $0.setTitleColor(.textWhite, for: .normal)
            $0.titleLabel?.font = .pretendard(.medium, ofSize: 16)
            $0.backgroundColor = .mainViolet
            $0.clipsToBounds = true
            $0.layer.cornerRadius = 12
        }
    
    // MARK: - Properties
    let alertText = BehaviorRelay<String>(value: "")
    var disposeBag = DisposeBag()
    var isChoice: Bool
    
    // MARK: - Initialization
    
    required init(isChoice: Bool) {
        self.isChoice = isChoice
        super.init(frame: .zero)
        render()
        configUI()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Functions
    func render() {
        self.addSubViews([box, alertLabel, completeButton, cancelButton, confirmButton])
        
        box.snp.makeConstraints { make in
            make.top.leading.bottom.trailing.equalToSuperview()
        }
        
        alertLabel.snp.makeConstraints { make in
            make.top.equalTo(box.snp.top).offset(32)
            make.centerX.equalToSuperview()
        }
        
        completeButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview().inset(16)
            make.height.equalTo(54)
        }
        
        cancelButton.snp.makeConstraints { make in
            make.leading.bottom.equalTo(box).inset(16)
            make.height.equalTo(54)
            make.trailing.equalTo(box.snp.centerX).offset(-4)
        }
        
        confirmButton.snp.makeConstraints { make in
            make.trailing.bottom.equalTo(box).inset(16)
            make.height.equalTo(54)
            make.leading.equalTo(box.snp.centerX).offset(4)
        }
    }
    
    func configUI() {
        alertText.asObservable().bind(to: alertLabel.rx.text).disposed(by: disposeBag)
        
        if isChoice {
            completeButton.isHidden = true
            confirmButton.isHidden = false
            cancelButton.isHidden = false
        } else {
            completeButton.isHidden = false
            confirmButton.isHidden = true
            cancelButton.isHidden = true
        }
    }
}
