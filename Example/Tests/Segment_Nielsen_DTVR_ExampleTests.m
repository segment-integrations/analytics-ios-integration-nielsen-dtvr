//
//  Segment_Nielsen_DTVR_ExampleTests.m
//  Segment-Nielsen-DTVR_ExampleTests
//
//  Created by David Hazama on 2019-05-31.
//

#import "SEGNielsenDTVRIntegrationFactory.h"
#import "SEGNielsenDTVRIntegration.h"

SpecBegin(SEGNielsenDTVRIntegration)

describe(@"SEGNielsenDTVRIntegration", ^{
    __block __strong NielsenAppApi *mockNielsenAppApi;
    __block SEGNielsenDTVRIntegration *integration;
    
    beforeEach(^{
        mockNielsenAppApi = mock([NielsenAppApi class]);
        
        NSDictionary *appInfo = @{
                                  @"appname": @"Test",
                                  @"appversion": @"0.1",
                                  @"sfcode": @"us-test",
                                  @"appId": @"test"
                                  };
        
        [given([mockNielsenAppApi initWithAppInfo:appInfo delegate:nil]) willReturn:mockNielsenAppApi];
        
        integration = [[SEGNielsenDTVRIntegration alloc] initWithSettings:@{
                                                                            @"appid": @"test",
                                                                            @"sendId3Events":@[
                                                                                    @"event 1",
                                                                                    @"event 2"
                                                                                    ],
                                                                            @"id3Property": @"id3TagKey",
                                                                            } andNielsen:mockNielsenAppApi];
    });
    
    describe(@"Video Content Started", ^{
        it(@"tracks play and loadMetadata properly with 'linear' load type", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"load_type": @"linear"
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            [integration track:payload];
            [verify(mockNielsenAppApi) play:@{
                                              @"channelName" : @"defaultChannelName",
                                              @"mediaURL" : @""
                                              }];
            [verify(mockNielsenAppApi) loadMetadata:@{
                                                      @"channelName" : @"defaultChannelName",
                                                      @"type": @"content",
                                                      @"adModel": @"1"
                                                      }];
        });
        
        it(@"tracks loadMetadata properly with 'dynamic' load type", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"load_type": @"dynamic"
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            [integration track:payload];
            
            [verify(mockNielsenAppApi) loadMetadata:@{
                                                      @"channelName" : @"defaultChannelName",
                                                      @"type": @"content",
                                                      @"adModel": @"2"
                                                      }];
        });
        
        it(@"does not set a 1 or 2 when the load_type is incorrect", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"load_type": @"test"
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            [integration track:payload];
            
            [verify(mockNielsenAppApi) loadMetadata:@{
                                                      @"channelName" : @"defaultChannelName",
                                                      @"type": @"content",
                                                      @"adModel": @""
                                                      }];
        });
    });
    
    
    
    it(@"tracks Video Playback Resumed", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Resumed"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) play:@{
                                          @"channelName" : @"defaultChannelName",
                                          @"mediaURL" : @""
                                          }];
    });
    
    it(@"tracks Video Playback Seek Completed", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Completed"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) play:@{
                                          @"channelName" : @"defaultChannelName",
                                          @"mediaURL" : @""
                                          }];
    });
    
    it(@"tracks Video Buffer Completed", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Completed"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) play:@{
                                          @"channelName" : @"defaultChannelName",
                                          @"mediaURL" : @""
                                          }];
    });
    
    it(@"tracks Video Playback Paused", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Paused"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) stop];
    });
    
    it(@"tracks Video Playback Interrupted", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Interrupted"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) stop];
    });
    
    it(@"tracks Video Content Completed", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Completed"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) stop];
    });
    
    it(@"tracks Video Playback Buffer Started", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Started"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) stop];
    });
    
    it(@"tracks Video Playback Seek Started", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Started"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) stop];
    });
    
    it(@"tracks Video Playback Completed", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Completed"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [(NielsenAppApi *)verify(mockNielsenAppApi) end];
    });
    
    it(@"tracks Application Backgrounded", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Paused"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verify(mockNielsenAppApi) stop];
    });
    
    it(@"exposes Nielsen opt-out URL", ^{
        [integration optOutURL];
        [verify(mockNielsenAppApi) optOutURL];
    });
    
    it(@"opts out Nielsen SDK", ^{
        [integration userOptOutStatus:@"nielsenappsdk://1"];
        [verify(mockNielsenAppApi) userOptOut:@"nielsenappsdk://1"];
    });
    
    it(@"opts in Nielsen SDK", ^{
        [integration userOptOutStatus:@"nielsenappsdk://0"];
        [verify(mockNielsenAppApi) userOptOut:@"nielsenappsdk://0"];
    });
    
    it(@"ID3 block tracks sendID3", ^{
        [integration sendID3Block](@"testID3tag");
        [verify(mockNielsenAppApi) sendID3:@"testID3tag"];
    });
    
    it(@"does not track a bogus event", ^{
        SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"testevent"
                                                               properties:@{
                                                                            @"asset_id" : @"1234",
                                                                            @"channel": @"defaultChannelName",
                                                                            @"adModel": @"linear"
                                                                            }
                                                                  context:@{}
                                                             integrations:@{}
                                    ];
        
        [integration track:payload];
        
        [verifyCount(mockNielsenAppApi, never()) stop];
        [(NielsenAppApi *)verifyCount(mockNielsenAppApi, never()) end];
        [(NielsenAppApi *)verifyCount(mockNielsenAppApi, never()) play:@{}];
        [verifyCount(mockNielsenAppApi, never()) loadMetadata:@{}];
    });
    
    describe(@"ID3 Tracking", ^{
        it(@"tracks sendID3 when 'event 1' is tracked', and uses proper key from settings", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"event 1"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"adModel": @"linear",
                                                                                @"id3TagKey": @"testid3",
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            
            [integration track:payload];
            [verify(mockNielsenAppApi) sendID3:@"testid3"];
        });
        
        it(@"tracks sendID3 when 'event 2' is tracked', and uses proper key from settings", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"event 2"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"adModel": @"linear",
                                                                                @"id3TagKey": @"testid3",
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            
            [integration track:payload];
            [verify(mockNielsenAppApi) sendID3:@"testid3"];
        });
        
        it(@"does not track sendID3 when a random event is called", ^{
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"random non-specified id3 event"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"adModel": @"linear",
                                                                                @"id3TagKey": @"testid3",
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            
            [integration track:payload];
            [verifyCount(mockNielsenAppApi, never()) sendID3:@"testid3"];
        });
        
        it(@"tracks sendID3 and uses default key of ID3 for payload properties", ^{
            integration = [[SEGNielsenDTVRIntegration alloc] initWithSettings:@{
                                                                                @"appid": @"test",
                                                                                @"sendId3Events":@[
                                                                                        @"event 1",
                                                                                        ],
                                                                                } andNielsen:mockNielsenAppApi];
            
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"event 1"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"adModel": @"linear",
                                                                                @"Id3": @"testid3",
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            
            [integration track:payload];
            [verify(mockNielsenAppApi) sendID3:@"testid3"];
        });
        
        it(@"does not track sendID3 when id3Property key is not defined, but default ID3 key is not transmitted", ^{
            integration = [[SEGNielsenDTVRIntegration alloc] initWithSettings:@{
                                                                                @"appid": @"test",
                                                                                @"sendId3Events":@[
                                                                                        @"event 1",
                                                                                        ],
                                                                                } andNielsen:mockNielsenAppApi];
            
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"event 1"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"adModel": @"linear",
                                                                                @"non-supported-id3-key": @"testid3",
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            
            [integration track:payload];
            [verifyCount(mockNielsenAppApi, never()) sendID3:@"testid3"];
        });
        
        it(@"does not track sendID3 when sendId3Events is empty", ^{
            integration = [[SEGNielsenDTVRIntegration alloc] initWithSettings:@{
                                                                                @"appid": @"test",
                                                                                @"sendId3Events":@[],
                                                                                } andNielsen:mockNielsenAppApi];
            
            SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"event 1"
                                                                   properties:@{
                                                                                @"asset_id" : @"1234",
                                                                                @"channel": @"defaultChannelName",
                                                                                @"adModel": @"linear",
                                                                                @"Id3": @"testid3",
                                                                                }
                                                                      context:@{}
                                                                 integrations:@{}
                                        ];
            
            [integration track:payload];
            [verifyCount(mockNielsenAppApi, never()) sendID3:@"testid3"];
        });
    });
});

SpecEnd

SpecBegin(SEGNielsenDTVRIntegrationFactory)

describe(@"SEGNielsenDTVRIntegrationFactory", ^{
    __block __strong NSDictionary *settings;
    
    beforeEach(^{
        settings = @{
                     @"appId": @"test"
                     };
    });
    
    it(@"creates a single integration when create is invoked", ^{
        SEGNielsenDTVRIntegrationFactory *factory = [[SEGNielsenDTVRIntegrationFactory alloc] init];
        SEGAnalytics *mockAnalytics = mock([SEGAnalytics class]);
        
        [factory createWithSettings:settings forAnalytics:mockAnalytics];
        expect([[factory integrationsForAppId:@"test"] count]).to.equal(1);
    });
    
    it(@"limits the number of created integrations to 4", ^{
        SEGNielsenDTVRIntegrationFactory *factory = [[SEGNielsenDTVRIntegrationFactory alloc] init];
        SEGAnalytics *mockAnalytics = mock([SEGAnalytics class]);
        
        for (int i=0; i<5; i++) {
            [factory createWithSettings:settings forAnalytics:mockAnalytics];
        }
        
        expect([[factory integrationsForAppId:@"test"] count]).to.equal(4);
    });
    
    it(@"removes an old integration instance when the limit of integrations is exceeded", ^{
        SEGNielsenDTVRIntegrationFactory *factory = [[SEGNielsenDTVRIntegrationFactory alloc] init];
        SEGAnalytics *mockAnalytics = mock([SEGAnalytics class]);
        
        for (int i=0; i<4; i++) {
            [factory createWithSettings:settings forAnalytics:mockAnalytics];
        }
        
        SEGNielsenDTVRIntegration *integration = [factory createWithSettings:settings forAnalytics:mockAnalytics];
        expect([[factory integrationsForAppId:@"test"] containsObject:integration]).to.beTruthy();
    });
});

SpecEnd
