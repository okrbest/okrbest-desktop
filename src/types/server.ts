// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.

export type RemoteInfo = {
    serverVersion?: string;
    siteName?: string;
    siteURL?: string;
    licenseSku?: string;
    helpLink?: string;
    reportProblemLink?: string;
    hasFocalboard?: boolean;
    hasPlaybooks?: boolean;
    hasUserSurvey?: boolean;
};

export type ClientConfig = {
    Version: string;
    SiteURL: string;
    SiteName: string;
    BuildBoards: string;
    HelpLink: string;
    ReportAProblemLink: string;
}

export type URLValidationResult = {
    status: string;
    validatedURL?: string;
    existingServerName?: string;
    serverVersion?: string;
    serverName?: string;
}

export type ErrorReason = {
    needsBasicAuth?: boolean;
    needsPreAuth?: boolean;
    needsClientCert?: boolean;
};

export type ServerTestResult = {
    data: RemoteInfo;
} | {
    error: Error & {
        errorReason?: ErrorReason;
    };
};
