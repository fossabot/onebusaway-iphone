//
//  OBABookmarkRouteDisambiguationViewController.m
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 5/31/16.
//  Copyright © 2016 OneBusAway. All rights reserved.
//

#import "OBABookmarkRouteDisambiguationViewController.h"
#import <OBAKit/OBAKit.h>
#import "OBATableRow.h"
#import "OBAEditStopBookmarkViewController.h"
#import "OBARouteFilter.h"
#import "OBAModelDAO.h"
#import "OBASegmentedRow.h"

@interface OBABookmarkRouteDisambiguationViewController ()
@property(nonatomic,strong) OBAArrivalsAndDeparturesForStopV2 *arrivalsAndDepartures;
@end

@implementation OBABookmarkRouteDisambiguationViewController

- (instancetype)initWithArrivalsAndDeparturesForStop:(OBAArrivalsAndDeparturesForStopV2*)arrivalsAndDepartures {
    self = [super init];

    if (self) {
        self.title = NSLocalizedString(@"Choose a Route", @"Title of OBABookmarkRouteDisambiguationViewController");
        _arrivalsAndDepartures = arrivalsAndDepartures;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"") style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];

    [self loadData];
}

#pragma mark - Actions

- (void)cancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Accessors

- (OBAModelDAO*)modelDAO {
    if (!_modelDAO) {
        _modelDAO = [OBAApplication sharedApplication].modelDao;
    }
    return _modelDAO;
}

- (OBARegionV2*)region {
    if (!_region) {
        _region = self.modelDAO.region;
    }
    return _region;
}

- (OBARouteFilter*)routeFilter {
    if (!_routeFilter) {
        OBAStopPreferencesV2 *stopPreferences = [self.modelDAO stopPreferencesForStopWithId:self.arrivalsAndDepartures.stopId];
        _routeFilter = [[OBARouteFilter alloc] initWithStopPreferences:stopPreferences];
    }
    return _routeFilter;
}

#pragma mark - Data Loading

- (void)loadData {
    OBATableSection *stopSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Bookmark the Stop", @"")];
    [stopSection addRow:^OBABaseRow *{
        OBATableRow *row = [[OBATableRow alloc] initWithTitle:self.arrivalsAndDepartures.stop.nameWithDirection action:^{
            OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithStop:self.arrivalsAndDepartures.stop region:self.region];
            OBAEditStopBookmarkViewController *bookmarkViewController = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
            [self.navigationController pushViewController:bookmarkViewController animated:YES];
        }];
        row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return row;
    }];

    OBATableSection *routeSection = [[OBATableSection alloc] initWithTitle:NSLocalizedString(@"Bookmark a Route at Stop", @"")];

    if (self.routeFilter.hasFilteredRoutes) {
        [routeSection addRow:^OBABaseRow *{
            OBASegmentedRow *segmentedRow = [[OBASegmentedRow alloc] initWithSelectionChange:^(NSUInteger selectedIndex) {
                self.routeFilter.showFilteredRoutes = !self.routeFilter.showFilteredRoutes;
                [self loadData];
            }];
            segmentedRow.items = @[NSLocalizedString(@"All Departures", @""), NSLocalizedString(@"Filtered Departures", @"")];
            segmentedRow.selectedItemIndex = self.routeFilter.showFilteredRoutes ? 0 : 1;
            return segmentedRow;
        }];
    }

    NSMutableSet *set = [NSMutableSet set];

    for (OBAArrivalAndDepartureV2 *dep in [self.arrivalsAndDepartures.arrivalsAndDepartures sortedArrayUsingSelector:@selector(compareRouteName:)]) {

        if (![self.routeFilter shouldShowRouteID:dep.routeId]) {
            continue;
        }

        // dedupe the list.
        if ([set containsObject:dep]) {
            continue;
        }
        [set addObject:dep];

        [routeSection addRow:^OBABaseRow *{
            OBATableRow *row = [[OBATableRow alloc] initWithTitle:[NSString stringWithFormat:@"%@ - %@", dep.bestAvailableName, dep.tripHeadsign] action:^{
                OBABookmarkV2 *bookmark = [[OBABookmarkV2 alloc] initWithArrivalAndDeparture:dep region:self.region];
                OBAEditStopBookmarkViewController *bookmarkViewController = [[OBAEditStopBookmarkViewController alloc] initWithBookmark:bookmark];
                [self.navigationController pushViewController:bookmarkViewController animated:YES];
            }];
            row.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return row;
        }];
    }
    self.sections = @[stopSection, routeSection];
    [self.tableView reloadData];
}

@end