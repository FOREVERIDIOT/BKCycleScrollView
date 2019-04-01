//
//  BKCycleScrollView.m
//  BKCycleScrollView
//
//  Created by BIKE on 2018/5/25.
//  Copyright © 2018年 BIKE. All rights reserved.
//

#import "BKCycleScrollView.h"
#import "BKCycleCollectionViewFlowLayout.h"
#import "BKCycleScrollCollectionViewCell.h"
#import "BKCycleScrollPageControl.h"
#import <ZFPlayer/ZFPlayer.h>
#import <ZFPlayer/ZFAVPlayerManager.h>
#import "BKCycleScrollVideoContentView.h"

NSInteger const kAllCount = 99999;//初始item数量
NSInteger const kMiddleCount = kAllCount/2-1;//item中间数

@interface BKCycleScrollView()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UIScrollViewDelegate,UIGestureRecognizerDelegate>

@property (nonatomic,strong) UICollectionView * collectionView;

@property (nonatomic,strong) BKCycleScrollPageControl * pageControl;

@property (nonatomic,strong) NSIndexPath * beginIndexPath;//collectionView开始显示的indexPath
@property (nonatomic,assign) NSInteger currentIndex;//当前所看到数据的索引
@property (nonatomic,strong) NSIndexPath * displayIndexPath;//collectionView当前显示的indexPath

@property (nonatomic,strong) NSTimer * timer;

@property (nonatomic,strong) ZFPlayerController * player;
@property (nonatomic,strong) BKCycleScrollVideoContentView * videoContentView;
@property (nonatomic,assign) NSUInteger playIndex;//播放所在的索引

@end

@implementation BKCycleScrollView

#pragma mark - setter

-(void)setDisplayBackgroundColor:(UIColor *)displayBackgroundColor
{
    _displayBackgroundColor = displayBackgroundColor;
    if (_collectionView) {
        _collectionView.backgroundColor = _displayBackgroundColor;
    }
}

-(void)setDisplayDataArr:(NSArray<BKCycleScrollDataModel *> *)displayDataArr
{
    _displayDataArr = displayDataArr;
    
    [self.player stopCurrentPlayingCell];
    
    if (_collectionView) {
        self.currentIndex = 0;
        [self.collectionView reloadData];
        
        if ([_displayDataArr count] > 0) {
            _collectionView.userInteractionEnabled = YES;
        }else {
            _collectionView.userInteractionEnabled = NO;
        }
        
        [self invalidateTimer];
        [self initTimer];
        
        [self assignPlayerData];
    }
    self.pageControl.numberOfPages = [_displayDataArr count];
    self.pageControl.currentPage = 0;
}

-(void)setIsAutoScroll:(BOOL)isAutoScroll
{
    _isAutoScroll = isAutoScroll;
    
    [self invalidateTimer];
    if (_isAutoScroll) {
        [self initTimer];
    }
}

-(void)setAutoScrollTime:(CGFloat)autoScrollTime
{
    _autoScrollTime = autoScrollTime;
    
    [self invalidateTimer];
    [self initTimer];
}

/******************************************************************************/

-(void)setLayoutStyle:(BKDisplayCellLayoutStyle)layoutStyle
{
    _layoutStyle = layoutStyle;
    [self resetLayoutProperty];
}

-(void)setItemSpace:(CGFloat)itemSpace
{
    _itemSpace = itemSpace;
    [self resetLayoutProperty];
}

-(void)setItemWidth:(CGFloat)itemWidth
{
    _itemWidth = itemWidth;
    [self resetLayoutProperty];
}

-(void)setItemReduceScale:(CGFloat)itemReduceScale
{
    _itemReduceScale = itemReduceScale;
    [self resetLayoutProperty];
}

-(void)setRadius:(CGFloat)radius
{
    _radius = radius;
    if (_collectionView) {
        [_collectionView reloadData];
    }
}

/******************************************************************************/

-(void)setProgressColor:(UIColor *)progressColor
{
    _progressColor = progressColor;
    self.videoContentView.progressColor = _progressColor;
}

-(void)setBufferColor:(UIColor *)bufferColor
{
    _bufferColor = bufferColor;
    self.videoContentView.bufferColor = _bufferColor;
}

-(void)setCurrentColor:(UIColor *)currentColor
{
    _currentColor = currentColor;
    self.videoContentView.currentColor = _currentColor;
}

/******************************************************************************/

-(void)setPageControlStyle:(BKCycleScrollPageControlStyle)pageControlStyle
{
    _pageControlStyle = pageControlStyle;
    
    if (_pageControlStyle == BKCycleScrollPageControlStyleNone) {
        [self.pageControl removeFromSuperview];
        self.pageControl = nil;
    }else{
        self.pageControl.pageControlStyle = _pageControlStyle;
    }
}

-(void)setDotHeight:(CGFloat)dotHeight
{
    _dotHeight = dotHeight;
    
    CGRect pageControlFrame = self.pageControl.frame;
    pageControlFrame.size.height = _dotHeight;
    pageControlFrame.origin.y = self.frame.size.height - _dotHeight - _dotBottomInset;
    self.pageControl.frame = pageControlFrame;
}

-(void)setDotSpace:(CGFloat)dotSpace
{
    _dotSpace = dotSpace;
    self.pageControl.dotSpace = _dotSpace;
}

-(void)setDotBottomInset:(CGFloat)dotBottomInset
{
    _dotBottomInset = dotBottomInset;
    CGRect pageControlFrame = self.pageControl.frame;
    pageControlFrame.origin.y = self.frame.size.height - pageControlFrame.size.height - _dotBottomInset;
    self.pageControl.frame = pageControlFrame;
}

-(void)setNormalDotColor:(UIColor *)normalDotColor
{
    _normalDotColor = normalDotColor;
    self.pageControl.normalDotColor = _normalDotColor;
}

-(void)setSelectDotColor:(UIColor *)selectDotColor
{
    _selectDotColor = selectDotColor;
    self.pageControl.selectDotColor = _selectDotColor;
}

-(void)setNormalDotImage:(UIImage *)normalDotImage
{
    _normalDotImage = normalDotImage;
    self.pageControl.normalDotImage = _normalDotImage;
}

-(void)setSelectDotImage:(UIImage *)selectDotImage
{
    _selectDotImage = selectDotImage;
    self.pageControl.selectDotImage = _selectDotImage;
}

#pragma mark - 初始化cell的Layout属性时重新创建collectionView

-(void)resetLayoutProperty
{
    if (_collectionView) {
        [_collectionView removeFromSuperview];
        _collectionView = nil;
        
        [self invalidateTimer];
        [self resetCurrentIndex:0 displayIndexPath:_beginIndexPath];
        [self collectionView];
        [self initTimer];
        
        [self assignPlayerData];
    }
    if (_pageControl) {
        self.pageControl.numberOfPages = [_displayDataArr count];
        self.pageControl.currentPage = 0;
    }
}

#pragma mark - delloc

- (void)dealloc
{
    [self invalidateTimer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - init

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (!newWindow) {
        [self invalidateTimer];
    }else{
        [self initTimer];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!_collectionView) {
        self.itemWidth = self.itemWidth == 0 ? self.frame.size.width : self.itemWidth;
        
        self.currentIndex = 0;
        [self collectionView];
        
        [self invalidateTimer];
        [self initTimer];
        
        [self assignPlayerData];
    }
    _pageControl.frame = CGRectMake(0, self.frame.size.height - self.dotBottomInset - self.dotHeight, self.frame.size.width, self.dotHeight);
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame displayDataArr:(NSArray*)displayDataArr
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
        
        self.displayDataArr = displayDataArr;
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame delegate:(id<BKCycleScrollViewDelegate>)delegate
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
        
        self.delegate = delegate;
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame delegate:(id<BKCycleScrollViewDelegate>)delegate displayDataArr:(NSArray*)displayDataArr
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initData];
        
        self.delegate = delegate;
        self.displayDataArr = displayDataArr;
    }
    return self;
}

/**
 初始数据
 */
-(void)initData
{
    self.backgroundColor = [UIColor clearColor];
    self.displayBackgroundColor = [UIColor clearColor];
    self.isAutoScroll = YES;
    self.autoScrollTime = 5;
    
    self.beginIndexPath = [NSIndexPath indexPathForItem:kMiddleCount inSection:0];
    self.displayIndexPath = self.beginIndexPath;
    self.currentIndex = 0;
    
    self.itemSpace = 0;
    self.itemWidth = self.frame.size.width;
    self.itemReduceScale = 0.1;
    self.radius = 0;
    
    self.dotHeight = 7;
    self.dotSpace = 7;
    self.dotBottomInset = 10;
    self.normalDotColor = [UIColor lightGrayColor];
    self.selectDotColor = [UIColor whiteColor];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

/**
 当前看见的索引重新赋值
 
 @param currentIndex 当前所看到数据的索引
 @param displayIndexPath collectionView当前显示的indexPath
 */
-(void)resetCurrentIndex:(NSInteger)currentIndex displayIndexPath:(NSIndexPath*)displayIndexPath
{
    self.currentIndex = currentIndex;
    self.displayIndexPath = displayIndexPath;
    
    self.pageControl.currentPage = self.currentIndex;
}

#pragma mark - Notification

-(void)didEnterBackgroundNotification:(NSNotification*)notification
{
    [self invalidateTimer];
}

-(void)didBecomeActiveNotification:(NSNotification*)notification
{
    [self initTimer];
}

#pragma mark - 视频

-(ZFPlayerController*)player
{
    if (!_player) {
        ZFAVPlayerManager * playerManager = [[ZFAVPlayerManager alloc] init];
        _player = [ZFPlayerController playerWithScrollView:self.collectionView playerManager:playerManager containerViewTag:99999];
        _player.controlView = self.videoContentView;
        _player.shouldAutoPlay = NO;
        _player.stopWhileNotVisible = YES;
        _player.playerDisapperaPercent = 1.0f;
        __weak typeof(self) weakSelf = self;
        [_player setPlayerPlayTimeChanged:^(id<ZFPlayerMediaPlayback>  _Nonnull asset, NSTimeInterval currentTime, NSTimeInterval duration) {
            if (asset.currentTime != 0) {
                BKCycleScrollDataModel * model = weakSelf.displayDataArr[weakSelf.playIndex];
                model.currentTime = currentTime;
                model.totalTime = duration;
                NSMutableArray * dataArr = [weakSelf.displayDataArr mutableCopy];
                [dataArr replaceObjectAtIndex:weakSelf.playIndex withObject:model];
                [weakSelf assignDisplayDataArr:[dataArr copy]];
            }
        }];
        [_player setPlayerDidToEnd:^(id<ZFPlayerMediaPlayback>  _Nonnull asset) {
            [weakSelf.player stopCurrentPlayingCell];
            BKCycleScrollDataModel * model = weakSelf.displayDataArr[weakSelf.playIndex];
            model.currentTime = 0;
            model.totalTime = 0;
            NSMutableArray * dataArr = [weakSelf.displayDataArr mutableCopy];
            [dataArr replaceObjectAtIndex:weakSelf.playIndex withObject:model];
            [weakSelf assignDisplayDataArr:[dataArr copy]];
        }];
    }
    return _player;
}

-(void)assignPlayerData
{
    NSMutableArray * videoUrls = [NSMutableArray array];
    for (BKCycleScrollDataModel * dataModel in self.displayDataArr) {
        if (dataModel.isVideo) {
            [videoUrls addObject:[NSURL URLWithString:dataModel.videoUrl]];
        }
    }
    self.player = nil;
    self.player.assetURLs = [videoUrls copy];
}

-(void)playVideoWithIndex:(NSUInteger)index cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    BKCycleScrollDataModel * dataModel = self.displayDataArr[index];
    if ([dataModel.videoUrl length] > 0) {
        [self.player playTheIndexPath:indexPath assetURL:[NSURL URLWithString:dataModel.videoUrl] scrollToTop:NO];
        if (dataModel.currentTime != 0) {
            [self.player.currentPlayerManager seekToTime:dataModel.currentTime completionHandler:nil];
        }
        self.videoContentView.dataObj = dataModel;
        self.playIndex = index;
    }
}

#pragma mark - 修改displayDataArr数据(不走setter的赋值)

/**
 修改displayDataArr数据(不走setter的赋值)
 
 @param dataArr 数据
 */
-(void)assignDisplayDataArr:(NSArray*)dataArr
{
    _displayDataArr = [dataArr copy];
}

#pragma mark - BKCycleScrollVideoContentView

-(BKCycleScrollVideoContentView*)videoContentView
{
    if (!_videoContentView) {
        _videoContentView = [[BKCycleScrollVideoContentView alloc] init];
    }
    return _videoContentView;
}

#pragma mark - NSTimer

-(void)initTimer
{
    if (!self.isAutoScroll) {
        return;
    }
    if ([self.displayDataArr count] > 0) {
        [self timer];
    }
}

-(NSTimer*)timer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(autoScrollTimer:) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

-(void)autoScrollTimer:(NSTimer*)timer
{
    if (_collectionView) {
        
        CGPoint point = [self convertPoint:self.collectionView.center toView:self.collectionView];
        NSIndexPath * currentIndexPath = [self.collectionView indexPathForItemAtPoint:point];
        
        NSIndexPath * nextIndexPath = [NSIndexPath indexPathForItem:currentIndexPath.item + 1 inSection:0];
        
        NSInteger selectIndex = [self getDisplayIndexWithTargetIndexPath:nextIndexPath];
        [self resetCurrentIndex:selectIndex displayIndexPath:nextIndexPath];
        
        [_collectionView scrollToItemAtIndexPath:self.displayIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

-(void)invalidateTimer
{
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - UICollectionView

-(BKCycleCollectionViewFlowLayout *)resetLayout
{
    CGFloat left_right_inset = (self.frame.size.width - self.itemWidth)/2;
    
    BKCycleCollectionViewFlowLayout * layout = [[BKCycleCollectionViewFlowLayout alloc] init];
    layout.layoutStyle = _layoutStyle;
    layout.itemSpace = _itemSpace;
    layout.itemInset = UIEdgeInsetsMake(0, left_right_inset, 0, left_right_inset);
    layout.itemReduceScale = _itemReduceScale;
    
    return layout;
}

-(UICollectionView*)collectionView
{
    if (!_collectionView) {
        
        BKCycleCollectionViewFlowLayout * layout = [self resetLayout];
        
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.displayBackgroundColor?self.displayBackgroundColor:[UIColor clearColor];
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.bounces = NO;
        _collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
        _collectionView.zf_scrollViewDerection = ZFPlayerScrollViewDerectionHorizontal;
        if (@available(iOS 11.0, *)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        [_collectionView registerClass:[BKCycleScrollCollectionViewCell class] forCellWithReuseIdentifier:@"BKCycleScrollCollectionViewCell"];
        
        [_collectionView scrollToItemAtIndexPath:self.displayIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        
        if ([self.displayDataArr count] > 0) {
            _collectionView.userInteractionEnabled = YES;
        }else {
            _collectionView.userInteractionEnabled = NO;
        }
        
        if (_pageControl) {
            [self insertSubview:_collectionView belowSubview:_pageControl];
        }else{
            [self addSubview:_collectionView];
        }
    }
    return _collectionView;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return kAllCount;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    BKCycleScrollCollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"BKCycleScrollCollectionViewCell" forIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    [cell setClickPlayBtnCallBack:^(NSUInteger currentIndex, NSIndexPath *currentIndexPath) {
        [weakSelf playVideoWithIndex:currentIndex cellForItemAtIndexPath:indexPath];
    }];
    
    NSInteger selectIndex = [self getDisplayIndexWithTargetIndexPath:indexPath];
    
    if ([self.delegate respondsToSelector:@selector(cycleScrollView:customDisplayCellStyleAtIndex:displayCell:)]) {
        [[cell subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self.delegate cycleScrollView:self customDisplayCellStyleAtIndex:selectIndex displayCell:cell];
        return cell;
    }
    
    cell.radius = self.radius;
    cell.placeholderImage = self.placeholderImage;
    cell.currentIndexPath = indexPath;
    if ([self.displayDataArr count] > selectIndex) {
        cell.currentIndex = selectIndex;
        cell.dataObj = self.displayDataArr[selectIndex];
    }
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self invalidateTimer];
    [self initTimer];
    
    NSInteger selectIndex = [self getDisplayIndexWithTargetIndexPath:indexPath];
    BKCycleScrollCollectionViewCell * cell = (BKCycleScrollCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
    if (self.selectItemAction) {
        self.selectItemAction(selectIndex, cell.displayImageView);
    }
}

/**
 获取目标indexPath显示的index
 
 @param indexPath 无线循环view上的目标显示的indexPath
 @return 实际显示的index数据
 */
-(NSInteger)getDisplayIndexWithTargetIndexPath:(NSIndexPath*)indexPath
{
    NSInteger currentIndex = indexPath.item;
    
    NSInteger selectIndex = _currentIndex;
    if (currentIndex != self.displayIndexPath.item) {
        selectIndex = selectIndex - (self.displayIndexPath.item - currentIndex);
    }
    
    NSInteger count = [self.displayDataArr count];
    if (count == 0) {
        selectIndex = 0;
    }else {
        if (selectIndex < 0) {
            selectIndex = (count + selectIndex % count) % count;
        }else if (selectIndex > count - 1) {
            selectIndex = selectIndex % count;
        }
    }
    
    return selectIndex;
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [scrollView zf_scrollViewDidScrollToTop];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [scrollView zf_scrollViewDidScroll];
    [self stopCurrentPlaying];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [scrollView zf_scrollViewWillBeginDragging];
    [self invalidateTimer];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [scrollView zf_scrollViewDidEndDraggingWillDecelerate:decelerate];
    [self initTimer];
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    //因为偏移量最终位置collectionView一屏中显示3个item 滚动停止后targetContentOffset肯定比目前显示cell的item小1 所以偏移量x调成了中心
    //因为缩放原因 cell的y值不一定为0 所以把偏移量y调成了中心
    CGPoint newTargetContentOffset = CGPointMake((*targetContentOffset).x + self.collectionView.frame.size.width/2, self.collectionView.frame.size.height/2);
    NSIndexPath * currentIndexPath = [self.collectionView indexPathForItemAtPoint:newTargetContentOffset];
    NSInteger selectIndex = [self getDisplayIndexWithTargetIndexPath:currentIndexPath];
    [self resetCurrentIndex:selectIndex displayIndexPath:currentIndexPath];
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [scrollView zf_scrollViewDidEndDecelerating];
    [self scrollViewDidEndScrollingAnimation:scrollView];
}

#pragma mark - 停止滚动后 修改当前所在indexPath

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    //延迟0s 防止定时器动画结束刹那闪屏现象
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSArray * visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];
        __block BOOL isExist = NO;
        [visibleIndexPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSIndexPath * indexPath = obj;
            //为了适配一屏显示多个时 返回滚动不出现bug 建议目前滚动item与初始item相差屏幕显示最大item数量*2 我这默认设置成99
            if (self.beginIndexPath.item + 99 > indexPath.item) {
                isExist = YES;
                *stop = YES;
            }
        }];
        
        if (!isExist) {
            self.displayIndexPath = self.beginIndexPath;
            [self.collectionView scrollToItemAtIndexPath:self.displayIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
    });
}

#pragma mark - 停止播放

/**
 停止播放
 ZFAVPlayerManager中playerDisapperaPercent==1.0时停止播放 collectionView滚动停止有时playerDisapperaPercent!=1.0 在scrollViewDidScroll中自己判断一下防止不停止播放
 */
-(void)stopCurrentPlaying
{
    __block BOOL isExist = NO;
    [[self.collectionView visibleCells] enumerateObjectsUsingBlock:^(__kindof UICollectionViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BKCycleScrollCollectionViewCell * cell = (BKCycleScrollCollectionViewCell*)obj;
        if (cell.currentIndex == self.playIndex) {
            isExist = YES;
            *stop = YES;
        }
    }];
    if (!isExist) {
        [self.player stopCurrentPlayingCell];
    }
}

#pragma mark - BKCycleScrollPageControl

-(BKCycleScrollPageControl*)pageControl
{
    if (_pageControlStyle != BKCycleScrollPageControlStyleNone) {
        if (!_pageControl) {
            _pageControl = [[BKCycleScrollPageControl alloc] initWithFrame:CGRectMake(0, self.frame.size.height - self.dotBottomInset - self.dotHeight, self.frame.size.width, self.dotHeight)];
            _pageControl.numberOfPages = [_displayDataArr count];
            _pageControl.currentPage = 0;
            _pageControl.pageControlStyle = _pageControlStyle;
            _pageControl.dotSpace = _dotSpace;
            _pageControl.normalDotColor = _normalDotColor;
            _pageControl.selectDotColor = _selectDotColor;
            _pageControl.normalDotImage = _normalDotImage;
            _pageControl.selectDotImage = _selectDotImage;
            [self addSubview:_pageControl];
        }
    }
    return _pageControl;
}

@end
