//
//  BKCycleCollectionViewFlowLayout.h
//  weixiutong
//
//  Created by zhaolin on 2018/5/25.
//  Copyright © 2018年 BIKE. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BKCycleScrollView.h"

@interface BKCycleCollectionViewFlowLayout : UICollectionViewFlowLayout

/** cell显示风格 */
@property (nonatomic,assign) BKDisplayCellLayoutStyle layoutStyle;
/** cell间距 默认0 */
@property (nonatomic,assign) CGFloat itemSpace;
/** cell距四周边界的偏移量 默认UIEdgeInsetsZero */
@property (nonatomic,assign) UIEdgeInsets itemInset;
/** 当layoutStyle = BKDisplayCellLayoutStyleMiddleLarger 时 除中间显示的cell不缩放外,其余cell缩放系数 默认0.1 */
@property (nonatomic,assign) CGFloat itemReduceScale;

@end
