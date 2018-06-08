//
//  BKCycleCollectionViewFlowLayout.m
//  weixiutong
//
//  Created by zhaolin on 2018/5/25.
//  Copyright © 2018年 BIKE. All rights reserved.
//

#import "BKCycleCollectionViewFlowLayout.h"

@implementation BKCycleCollectionViewFlowLayout

- (void)prepareLayout
{
    [super prepareLayout];
    
    self.itemSize = CGSizeMake(self.collectionView.frame.size.width - self.itemInset.left - self.itemInset.right, self.collectionView.frame.size.height - self.itemInset.top - self.itemInset.bottom);
    self.minimumLineSpacing = self.itemSpace;
    self.minimumInteritemSpacing = 0;
    self.sectionInset = self.itemInset;
    self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds
{
    return YES;
}

-(NSArray*)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray * array = [super layoutAttributesForElementsInRect:rect];
    
    if (_layoutStyle == BKDisplayCellLayoutStyleNormal) {
        return array;
    }
    
    CGRect visiableRect;
    visiableRect.size = self.collectionView.frame.size;
    visiableRect.origin = self.collectionView.contentOffset;
    
    CGFloat centenrX = self.collectionView.contentOffset.x + self.collectionView.frame.size.width/2;
    for (UICollectionViewLayoutAttributes* attributes in array) {
        if (!CGRectIntersectsRect(visiableRect, attributes.frame)) continue;
        
        CGFloat itemCenterX = attributes.center.x;
        CGFloat gap = fabs(itemCenterX - centenrX);
//        CGFloat max_gap = self.minimumLineSpacing + self.itemSize.width;
//        if (gap > max_gap) {
//            gap = max_gap;
//        }
        CGFloat scale = 1 - (gap / (self.collectionView.frame.size.width/2)) * self.itemReduceScale;
        
        attributes.transform3D = CATransform3DMakeScale(scale, scale, 1.0);
    }
    return array;
}

-(CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    CGRect lastRect;
    lastRect.origin = self.collectionView.contentOffset;
    lastRect.size = self.collectionView.frame.size;
    
    CGFloat centerX = self.collectionView.contentOffset.x + self.collectionView.frame.size.width / 2;
    
    NSArray * array = [self layoutAttributesForElementsInRect:lastRect];
    
    CGFloat maxX = FLT_MIN;
    CGFloat minX = FLT_MAX;
    CGFloat adjustOffsetX = FLT_MAX;
    for (UICollectionViewLayoutAttributes * attributes in array) {
        if (velocity.x == 0) {//速度为0时判断 哪个item离中心近
            if (fabs(attributes.center.x - centerX) < fabs(adjustOffsetX)) {
                adjustOffsetX = attributes.center.x - centerX;
            }
        }else if (velocity.x > 0) {//往左划 选最大
            if (maxX == FLT_MIN) {
                maxX = attributes.center.x;
                adjustOffsetX = attributes.center.x - centerX;
            }else if (attributes.center.x > maxX) {
                maxX = attributes.center.x;
                adjustOffsetX = attributes.center.x - centerX;
            }
        }else if (velocity.x < 0) {//往右划 选最小
            if (minX == FLT_MAX) {
                minX = attributes.center.x;
                adjustOffsetX = attributes.center.x - centerX;
            }else if (attributes.center.x < minX) {
                minX = attributes.center.x;
                adjustOffsetX = attributes.center.x - centerX;
            }
        }
    }
    
    CGFloat contentOffsetX = self.collectionView.contentOffset.x + adjustOffsetX;
    CGPoint targetContentOffset = CGPointMake(contentOffsetX, self.collectionView.contentOffset.y);

    return targetContentOffset;
}

@end
