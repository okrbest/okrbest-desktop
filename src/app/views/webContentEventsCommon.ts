// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.
import path from 'path';

import type {Event, WebContentsConsoleMessageEventParams} from 'electron';

import type {Logger} from 'common/log';
import {getLevel} from 'common/log';
import {parseURL} from 'common/utils/url';

import {protocols} from '../../../electron-builder.json';

export const generateHandleConsoleMessage = (log: Logger) => (event: Event<WebContentsConsoleMessageEventParams>) => {
    const wcLog = log.withPrefix('renderer');
    let logFn = wcLog.debug;
    switch (event.level) {
    case 'error':
        logFn = wcLog.error;
        break;
    case 'warning':
        logFn = wcLog.warn;
        break;
    }

    // Only include line entries if we're debugging
    const entries = [sanitizeMessage(event.sourceId, event.message)];
    if (['debug', 'silly'].includes(getLevel())) {
        entries.push(sanitizeMessage(event.sourceId, `(${path.basename(event.sourceId)}:${event.lineNumber})`));
    }

    logFn(...entries);
};

function sanitizeMessage(sourceURL: string, message: string) {
    const parsedURL = parseURL(sourceURL);
    if (!parsedURL) {
        return message;
    }
    return message.replace(parsedURL.host, '<host>');
}

// Get all registered protocol schemes from electron-builder.json
const registeredSchemes = protocols?.[0]?.schemes ?? [];

export function isCustomProtocol(url: URL) {
    if (url.protocol === 'http:' || url.protocol === 'https:') {
        return false;
    }
    // Check if the protocol is one of our registered schemes
    const protocolWithoutColon = url.protocol.slice(0, -1);
    return !registeredSchemes.includes(protocolWithoutColon);
}

export function isMattermostProtocol(url: URL) {
    // Check if the protocol matches any of our registered schemes (okrbest, mattermost)
    const protocolWithoutColon = url.protocol.slice(0, -1);
    return registeredSchemes.includes(protocolWithoutColon);
}
