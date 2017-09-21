//
//  DSA_ContentShelvesConfig.m
//  DSA
//
//  Created by Mike Close on 7/24/14.
//  Copyright (c) 2014 Salesforce. All rights reserved.
//

#import "DSA_ContentShelvesConfig.h"

@interface DSA_ContentShelvesConfig()
@property (nonatomic, strong)   NSDictionary    *config;
@property (nonatomic, strong)   NSError         *configParsingError;
- (BOOL)loadConfigFromPath:(NSString *)path error:(NSError**)error;
@end

@implementation DSA_ContentShelvesConfig
- (id)initWithConfigPath:(NSString *)path
{
    if (self = [super init])
    {
        NSError *error = nil;
        [self loadConfigFromPath:path error:&error];
        if (error && [[error localizedDescription] length] > 0)
        {
            MMLog(@"There was an error loading the shelf config file from %@\nError: %@", path,[error localizedDescription]);
            return nil;
        }
    }
    return self;
}

- (BOOL)loadConfigFromPath:(NSString *)path error:(NSError**)error
{
    BOOL success = YES;
    
    // check to see if we should be using the test config:
    NSString *testConfigName = [[[NSProcessInfo processInfo] environment] objectForKey: @"CONTENT_SHELVES_CONFIG_NAME"];
    if (testConfigName)
    {
        path = [[NSBundle mainBundle] pathForResource:testConfigName ofType:@"json"];
    }
    
    NSString *rawJson = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:error];
    
    if (rawJson == nil) return NO;
    
    NSDictionary *serializedJson = [NSJSONSerialization JSONObjectWithData:[rawJson dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingMutableLeaves & NSJSONReadingMutableContainers) error:error];
    
    [self setConfig:serializedJson];
    
    __weak typeof(self) weakSelf = self;
    [[self config] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        SEL configSelector = [DSA_ContentShelvesConfig setterSelectorForConfigKey:key];
        if ([weakSelf respondsToSelector:configSelector])
        {
            [weakSelf setValue:obj forKey:key];
            
            // the error may have been populated during child object creation
            if ([weakSelf configParsingError] && [[[weakSelf configParsingError] localizedDescription] length] > 0)
            {
                *stop = YES;
            }
        }
        else
        {
            MMLog(@"!!! Content Shelves Config Error !!!\n\nThe key \"%@\" in your JSON is not recognized by the DSA_ContentShelvesConfig model.", key);
            NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The DSA_ContentShelvesConfig found a key in the configuration that it doesn't understand: %@",key],
                                        @"key": key};
            [weakSelf setConfigParsingError:[[NSError alloc] initWithDomain:kContentShelvesErrorDomain code:DSAContentShelvesErrorInvalidKey userInfo:errorInfo]];
            *stop = YES;
        }
    }];
    
    NSError *parsingError = [self configParsingError];
    if (parsingError && [[parsingError localizedDescription] length] > 1) {
        if (error) {
            *error = parsingError;
            success = NO;
        }
    }
    
    return success;
}

+ (SEL)setterSelectorForConfigKey:(NSString *)key
{
    return NSSelectorFromString([self setterSelectorStringForConfigKey:key]);
}

+ (NSString *)setterSelectorStringForConfigKey:(NSString *)key
{
    NSString *firstChar = [key substringToIndex:1];
    NSString *capitalizedKey = [[firstChar uppercaseString] stringByAppendingString:[key substringFromIndex:1]];
    NSString *selectorKey = [NSString stringWithFormat:@"set%@:", capitalizedKey];
    return selectorKey;
}

- (DSA_ContentShelfConfig *)shelfConfigForSection:(NSUInteger)section
{
    __block DSA_ContentShelfConfig *shelfConfig = nil;
    [[self customShelfConfigs] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([(DSA_ContentShelfConfig*)obj shelfIndex] == section)
        {
            shelfConfig = obj;
            *stop = YES;
        }
    }];
    
    return shelfConfig ?: [self defaultShelfConfig];
}

- (void)setCustomShelfConfigs:(NSArray *)customShelfConfigs
{
    NSMutableArray *tmpShelfConfigs = [NSMutableArray array];
    __block NSError *error = nil;
    __weak typeof(self) weakSelf = self;
    [customShelfConfigs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        DSA_ContentShelfConfig *shelfConfig = [[DSA_ContentShelfConfig alloc] initWithDictionary:obj error:&error];
        
        if (error && [[error localizedDescription] length] > 1)
        {
            [weakSelf setConfigParsingError:error];
            *stop = YES;
        }
        
        [tmpShelfConfigs addObject:shelfConfig];
    }];
    
    _customShelfConfigs = [[NSArray alloc] initWithArray:tmpShelfConfigs];
}

- (void)setDefaultShelfConfig:(id)defaultShelfConfig
{
    if (![defaultShelfConfig isKindOfClass:[NSDictionary class]])
    {
        MMLog(@"!!! The default shelf config setter expects an NSDictionary instance, received a %@.\n", [defaultShelfConfig classNameForClass:[defaultShelfConfig class]]);
    }
    
    NSError *error = nil;
    DSA_ContentShelfConfig *shelfConfig = [[DSA_ContentShelfConfig alloc] initWithDictionary:defaultShelfConfig error:&error];
    if (error && [[error localizedDescription] length] > 1)
    {
        [self setConfigParsingError:error];
        return;
    }
    _defaultShelfConfig = shelfConfig;
}

@end




/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - DSA_ContentShelfConfig Implementation
/////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

@interface DSA_ContentShelfConfig()
@property (nonatomic, strong) NSError       *configParsingError;
@end
@implementation DSA_ContentShelfConfig

- (id)initWithDictionary:(NSDictionary *)dict error:(NSError **)error
{
    if (self = [super init])
    {
        __weak typeof(self) weakSelf = self;
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            SEL configSelector = [DSA_ContentShelvesConfig setterSelectorForConfigKey:key];
            if ([weakSelf respondsToSelector:configSelector])
            {
                [weakSelf setValue:obj forKey:key];
                
                if ([weakSelf configParsingError] && [[[weakSelf configParsingError] localizedDescription] length] > 0)
                {
                    *stop = YES;
                }
            }
            else
            {
                MMLog(@"!!! Content Shelf Config Error !!!\n\nThe key \"%@\" in your JSON is not recognized by the DSA_ContentShelfConfig model.\n", key);
                NSDictionary *errorInfo = @{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"The DSA_ContentShelfConfig found a key in the configuration that it doesn't understand: %@",key],
                                            @"key": key};
                 [self setConfigParsingError:[[NSError alloc] initWithDomain:kContentShelvesErrorDomain code:DSAContentShelvesErrorInvalidKey userInfo:errorInfo]];
                *stop = YES;
            }
        }];
        
        NSError *parsingError = [self configParsingError];
        if (parsingError && [[parsingError localizedDescription] length] > 1) {
            if (error) {
                *error = parsingError;
            }
        }
    }

    return self;
}



#pragma mark - Custom Setters

- (void)setHeaderColors:(NSArray *)headerColors
{
    NSArray *colors = [self parseColorsObject:headerColors forKey:kContentShelvesConfigKey_HeaderColors];
    _headerColors = colors ?: _headerColors;
}

- (void)setSectionBackgroundColors:(NSArray *)sectionBackgroundColors
{
    NSArray *colors = [self parseColorsObject:sectionBackgroundColors forKey:kContentShelvesConfigKey_SectionBackgroundColors];
    _sectionBackgroundColors = colors ?: _sectionBackgroundColors;
}

- (void)setSectionPadding:(NSArray*)sectionPadding
{
    UIEdgeInsets inset = UIEdgeInsetsMake([(NSNumber*)[(NSArray*)sectionPadding objectAtIndex:0] floatValue],
                                           [(NSNumber*)[(NSArray*)sectionPadding objectAtIndex:3] floatValue],
                                           [(NSNumber*)[(NSArray*)sectionPadding objectAtIndex:2] floatValue],
                                           [(NSNumber*)[(NSArray*)sectionPadding objectAtIndex:1] floatValue]);
    _sectionPadding = sectionPadding;
    [self setSectionInset:inset];
}

- (void)setHeaderBorderColor:(id)headerBorderColor
{
    UIColor *color = [self parseColorObject:headerBorderColor forKey:kContentShelvesConfigKey_HeaderBorderColor];
    if(color == nil) return;
    _headerBorderColor = color;
}

- (void)setHeaderLabelColor:(id)headerLabelColor
{
    UIColor *color = [self parseColorObject:headerLabelColor forKey:kContentShelvesConfigKey_HeaderLabelColor];
    if(color == nil) return;
    _headerLabelColor = color;
}

- (void)setThumbnailBorderColor:(id)thumbnailBorderColor
{
    UIColor *color = [self parseColorObject:thumbnailBorderColor forKey:kContentShelvesConfigKey_ThumbnailBorderColor];
    if(color == nil) return;
    _thumbnailBorderColor = color;
}

- (void)setThumbnailBorderThickness:(NSArray *)thumbnailBorderThickness
{
    self.thumbnailBorderOutsets = UIEdgeInsetsMake([(NSNumber*)[(NSArray*)thumbnailBorderThickness objectAtIndex:0] floatValue],
                                                   [(NSNumber*)[(NSArray*)thumbnailBorderThickness objectAtIndex:3] floatValue],
                                                   [(NSNumber*)[(NSArray*)thumbnailBorderThickness objectAtIndex:2] floatValue],
                                                   [(NSNumber*)[(NSArray*)thumbnailBorderThickness objectAtIndex:1] floatValue]);
    _thumbnailBorderThickness = thumbnailBorderThickness;
}

- (void)setThumbnailBackgroundColor:(id)thumbnailBackgroundColor
{
    UIColor *color = [self parseColorObject:thumbnailBackgroundColor forKey:kContentShelvesConfigKey_ThumbnailBackgroundColor];
    if(color == nil) return;
    _thumbnailBackgroundColor = color;
}

- (void)setThumbnailLabelColor:(id)thumbnailLabelColor
{
    UIColor *color = [self parseColorObject:thumbnailLabelColor forKey:kContentShelvesConfigKey_ThumbnailLabelColor];
    if(color == nil) return;
    _thumbnailLabelColor = color;
}

- (void)setThumbnailUnavailableFontColor:(id)thumbnailUnavailableFontColor
{
    UIColor *color = [self parseColorObject:thumbnailUnavailableFontColor forKey:kContentShelvesConfigKey_ThumbnailUnavailableFontColor];
    if(color == nil) return;
    _thumbnailUnavailableFontColor = color;
}

- (void)setHeaderLabelIconImage:(id)headerLabelIconImage
{
    UIImage *icon = [self imageFromFileName:headerLabelIconImage];
    if (icon == nil)
    {
        return;
    }
    _headerLabelIconImage = icon;
}

- (void)setThumbnailUnavailableIcon:(id)thumbnailUnavailableIcon
{
    UIImage *icon = [self imageFromFileName:thumbnailUnavailableIcon];
    if (icon == nil)
    {
        return;
    }
    _thumbnailUnavailableIcon = icon;
}



#pragma mark - Custom Getters
- (CGSize)thumbnailCGSize
{
    CGSize size = CGSizeMake([(NSNumber*)[(NSArray*)_thumbnailSize objectAtIndex:0] floatValue],
                             [(NSNumber*)[(NSArray*)_thumbnailSize objectAtIndex:1] floatValue]);
    return size;
}

- (CGSize)cellCGSize
{
    int cellsPerRow;
    switch ([self interfaceOrientation])
    {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            cellsPerRow = self.itemsPerRowLandscape;
            break;
        default:
            cellsPerRow = self.itemsPerRowPortrait;
    }
    return CGSizeMake([self screenSize].width / cellsPerRow,
                      self.thumbnailCGSize.height + (self.minimumLineSpacing * 3));
}



#pragma mark - Wrapped dependencies for simplified testing

- (CGSize)screenSize
{
    return [[UIScreen mainScreen] bounds].size;
}

- (NSInteger)interfaceOrientation
{
    return [[UIApplication sharedApplication] statusBarOrientation];
}



#pragma mark - Utility Methods

- (NSArray *)parseColorsObject:(NSArray *)colors forKey:(NSString *)key
{
    if (![colors isKindOfClass:[NSArray class]])
    {
        [self activateColorsArrayErrorForKey:key];
        return nil;
    }
    
    __block NSMutableArray *tmpColors = [NSMutableArray array];
    __weak typeof(self) weakSelf = self;
    __block BOOL success = YES;
    
    [colors enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIColor *color = [weakSelf parseColorObject:obj forKey:key];
        if(color == nil) {
            *stop = YES;
            success = NO;
        } else {
            [tmpColors addObject:color];
        }
    }];
    
    if (!success) tmpColors = nil;
    return tmpColors;
}

- (UIColor *)parseColorObject:(NSDictionary *)color forKey:(NSString *)key
{
    if (([color objectForKey:@"r"] == nil) ||
        ([color objectForKey:@"g"] == nil) ||
        ([color objectForKey:@"b"] == nil))
    {
        [self activateColorFormatErrorForKey:key];
        return nil;
    }
    
    float red = [(NSNumber*)[color objectForKey:@"r"] floatValue];
    float green = [(NSNumber*)[color objectForKey:@"g"] floatValue];
    float blue = [(NSNumber*)[color objectForKey:@"b"] floatValue];
    float alpha = [(NSNumber*)[color objectForKey:@"a"] floatValue];
    
    if (alpha > 1) return nil;
    
    red = (red <= 1) ? red : red/255;
    green = (green <= 1) ? green : green/255;
    blue = (blue <= 1) ? blue : blue/255;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (UIImage *)imageFromFileName:(NSString *)fileName
{
    NSArray *fileNameParts = [fileName componentsSeparatedByString:@"."];
    UIImage *icon = [UIImage imageNamed:[fileNameParts objectAtIndex:0]];
    if(icon == nil)
    {
        NSString *description = [NSString stringWithFormat:@"Could not load image named %@", fileName];
        NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:description};
        [self setConfigParsingError:[[NSError alloc] initWithDomain:kContentShelvesErrorDomain code:DSAContentShelvesErrorInvalidDataStructure userInfo:errorInfo]];
        return nil;
    }
    return icon;
}

- (void)activateColorFormatErrorForKey:(NSString *)key
{
    NSString *description = [NSString stringWithFormat:@"The %@ array must have either 3 or 4 items. [R,G,B] or [R,G,B,A]", key];
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:description};
    [self setConfigParsingError:[[NSError alloc] initWithDomain:kContentShelvesErrorDomain code:DSAContentShelvesErrorInvalidDataStructure userInfo:errorInfo]];
}

- (void)activateColorsArrayErrorForKey:(NSString *)key
{
    NSString *description = [NSString stringWithFormat:@"The %@ property is expected to be an array of color objects. [{\"r\":203,\"g\":203,\"b\":203,\"a\":1}, {\"r\":255,\"g\":255,\"b\":255,\"a\":1}, {\"r\":255,\"g\":255,\"b\":255,\"a\":1}, {\"r\":203,\"g\":203,\"b\":203,\"a\":1}]", key];
    NSDictionary *errorInfo = @{NSLocalizedDescriptionKey:description};
    [self setConfigParsingError:[[NSError alloc] initWithDomain:kContentShelvesErrorDomain code:DSAContentShelvesErrorInvalidDataStructure userInfo:errorInfo]];
}

@end



// Configuration Keys

NSString *const kContentShelvesConfigKey_HeaderColors = @"headerColors";
NSString *const kContentShelvesConfigKey_HeaderBorderColor = @"headerBorderColor";
NSString *const kContentShelvesConfigKey_HeaderLabelColor = @"headerLabelColor";
NSString *const kContentShelvesConfigKey_SectionBackgroundColors = @"sectionBackgroundColors";
NSString *const kContentShelvesConfigKey_ThumbnailLabelColor = @"thumbnailLabelColor";
NSString *const kContentShelvesConfigKey_ThumbnailBorderColor = @"thumbnailBorderColor";
NSString *const kContentShelvesConfigKey_ThumbnailBackgroundColor = @"thumbnailBackgroundColor";
NSString *const kContentShelvesConfigKey_ThumbnailUnavailableFontColor = @"thumbnailUnavailableFontColor";

NSString *const kContentShelvesErrorDomain = @"contentShelvesErrorDomain";