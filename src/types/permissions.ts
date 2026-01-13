// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.

import type {UniqueServer} from './config';

export type Permissions = {
    [permission: string]: {
        allowed: boolean;
        alwaysDeny?: boolean;
    };
};

export type UniqueServerWithPermissions = {server: UniqueServer; permissions: Permissions};
