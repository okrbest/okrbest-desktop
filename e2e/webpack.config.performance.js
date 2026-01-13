// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.

const glob = require('glob');
const {merge} = require('webpack-merge');

const test = require('./webpack.config.test');

module.exports = merge(test, {
    entry: {
        e2e: glob.sync('./e2e/performance/**/*.test.js'),
    },
});
