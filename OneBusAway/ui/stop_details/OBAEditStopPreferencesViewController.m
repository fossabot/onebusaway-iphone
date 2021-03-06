/**
 * Copyright (C) 2009 bdferris <bdferris@onebusaway.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OBAEditStopPreferencesViewController.h"
#import "OBAStopViewController.h"
#import "UITableViewController+oba_Additions.h"
#import "UITableViewCell+oba_Additions.h"
#import "OBAAnalytics.h"
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>

@interface OBAEditStopPreferencesViewController ()<DZNEmptyDataSetSource>
@property(nonatomic,strong) OBAModelDAO *modelDAO;
@property(nonatomic,strong) OBAStopV2 *stop;
@property(nonatomic,strong) NSArray *routes;
@property(nonatomic,strong) OBAStopPreferencesV2 *preferences;
@end

@implementation OBAEditStopPreferencesViewController

- (instancetype)initWithModelDAO:(OBAModelDAO*)modelDAO stop:(OBAStopV2 *)stop {
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        _stop = stop;
        _modelDAO = modelDAO;
        _preferences = [_modelDAO stopPreferencesForStopWithId:_stop.stopId];
        _routes = [_stop.routes sortedArrayUsingSelector:@selector(compareUsingName:)];

        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelButton;

        UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
        self.navigationItem.rightBarButtonItem = saveButton;

        self.navigationItem.title = NSLocalizedString(@"Filter Routes",);
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];

    [OBAAnalytics reportScreenView:[NSString stringWithFormat:@"View: %@", [self class]]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.emptyDataSetSource = self;
    self.tableView.tableFooterView = [UIView new];
}

#pragma mark - DZNEmptyDataSetSource

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No Routes Found",)];
}

#pragma mark - Table View

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.routes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    OBARouteV2 *route = self.routes[indexPath.row];

    UITableViewCell *cell = [UITableViewCell getOrCreateCellForTableView:tableView cellId:@"identifier"];
    cell.textLabel.text = [route safeShortName];

    BOOL checked = ![_preferences isRouteIDDisabled:route.routeId];
    cell.accessoryType = checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.textLabel.font = [OBATheme bodyFont];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    OBARouteV2 *route = _routes[indexPath.row];
    cell.accessoryType = [_preferences toggleRouteID:route.routeId] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

- (void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)save:(id)sender {
    [self.modelDAO setStopPreferences:self.preferences forStopWithId:self.stop.stopId];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
