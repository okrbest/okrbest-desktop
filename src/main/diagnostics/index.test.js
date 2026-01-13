// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.

import Diagnostics from '.';

jest.mock('app/mainWindow/mainWindow', () => ({}));
jest.mock('common/config', () => ({
    configFilePath: 'mock/config/filepath/',
}));

describe('main/diagnostics/index', () => {
    it('should be initialized with correct values', () => {
        const d = Diagnostics;
        expect(d.stepTotal).toBe(0);
        expect(d.stepCurrent).toBe(0);
        expect(d.report).toEqual([]);
    });

    it('should count the steps correctly', () => {
        const d = Diagnostics;
        expect(d.getStepCount()).toBe(12);
    });
});
