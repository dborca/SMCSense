@import Cocoa;
#import "NSMenuItem Additions.h"

@interface MenuMutableAttributedString : NSMutableAttributedString
{
	NSMutableAttributedString* contents;
	CGSize size;
}
- (void)appendTableCellWithString:(NSString*)string table:(NSTextTable*)table textAlignment:(NSTextAlignment)textAlignment verticalAlignment:(NSTextBlockVerticalAlignment)verticalAlignment font:(NSFont*)font color:(NSColor*)color row:(int)row column:(int)column;
- (CGSize)size;
@end

@implementation MenuMutableAttributedString

// Methods to override in subclass

- (instancetype)init
{
	if(self = [super init])
		contents = [[NSMutableAttributedString alloc] init];
	return self;
}

- (instancetype)initWithAttributedString:(NSAttributedString*)anAttributedString
{
	if(self = [self init])
	{
		if(anAttributedString)
			[contents setAttributedString:anAttributedString];
	}
	return self;
}

- (NSString*)string
{
	return [contents string];
}

- (NSDictionary*)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRange*)range
{
	return [contents attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString*)string
{
	[contents replaceCharactersInRange:range withString:string];
}

- (void)setAttributes:(NSDictionary*)attributes range:(NSRange)range
{
	[contents setAttributes:attributes range:range];
}

- (id)copyWithZone:(NSZone*)zone
{
	MenuMutableAttributedString* copy = [MenuMutableAttributedString allocWithZone:zone];
	copy->contents = [contents copyWithZone:zone];
	copy->size = size;
	return copy;
}

// NOTE: AppKit additions produce invalid values here, provide our own implementation

- (NSRect)boundingRectWithSize:(NSSize)aSize options:(NSStringDrawingOptions)options // Not called after MAC_OS_X_VERSION_10_14
{
	return [self boundingRectWithSize:aSize options:options context:nil];
}

- (NSRect)boundingRectWithSize:(NSSize)aSize options:(NSStringDrawingOptions)options context:(NSStringDrawingContext*)context
{
	return NSMakeRect(0, 0, size.width, size.height);
}

// Helper method for adding table cell into the attributed string

- (void)appendTableCellWithString:(NSString*)string table:(NSTextTable*)table textAlignment:(NSTextAlignment)textAlignment verticalAlignment:(NSTextBlockVerticalAlignment)verticalAlignment font:(NSFont*)font color:(NSColor*)color row:(int)row column:(int)column;
{
	CGSize stringSize = [string sizeWithAttributes:@{ NSFontAttributeName : font }];

	NSTextTableBlock* block = [[NSTextTableBlock alloc] initWithTable:table startingRow:row rowSpan:1 startingColumn:column columnSpan:1];

	if(column > 0)
		[block setContentWidth:stringSize.width type:NSTextBlockAbsoluteValueType];

	block.verticalAlignment = verticalAlignment;

	NSMutableParagraphStyle* paragraphStyle = [NSMutableParagraphStyle new];
	[paragraphStyle setTextBlocks:@[ block ]];
	[paragraphStyle setAlignment:textAlignment];

	string = [string stringByAppendingString:@"\n"];

	NSMutableAttributedString* cellString = [[NSMutableAttributedString alloc] initWithString:string];
	[cellString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [cellString length])];
	[cellString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, [cellString length])];
	if (color) {
		[cellString addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [cellString length])];
	}

	size.width += stringSize.width;
	if(size.height < stringSize.height)
		size.height = stringSize.height;

	[self appendAttributedString:cellString];
}

- (CGSize)size
{
	return size;
}

@end

@implementation NSMenuItem (FileIcon)

- (void)setActivationString:(NSString*)anActivationString withFont:(NSFont*)aFont andColor:(NSColor*)aColor
{
	MenuMutableAttributedString* attributedTitle = [MenuMutableAttributedString new];
	NSTextTable* table = [NSTextTable new];
	[table setNumberOfColumns:2];

	NSFont* font = self.menu.font ?: [NSFont menuFontOfSize:0];
	[attributedTitle appendTableCellWithString:self.title table:table textAlignment:NSLeftTextAlignment verticalAlignment:NSTextBlockMiddleAlignment font:font color:aColor row:0 column:0];
	[attributedTitle appendTableCellWithString:anActivationString table:table textAlignment:NSRightTextAlignment verticalAlignment:aFont && aFont.pointSize >= 13 ? NSTextBlockBottomAlignment : NSTextBlockMiddleAlignment font:(aFont ?: font) color:aColor row:0 column:1];

	NSString* plainTitle = self.title;
	self.attributedTitle = attributedTitle;
	self.title = plainTitle;
}
@end
