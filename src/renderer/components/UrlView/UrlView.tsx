// Copyright (c) 2016-present Mattermost, Inc. All Rights Reserved.
// Copyright (c) 2024-present OKR Best. All Rights Reserved.
// See LICENSE.txt for license information.
// Modified for OKR Best project.

import React, {useEffect, useRef, useState} from 'react';

import './UrlView.scss';

export default function UrlView() {
    const urlRef = useRef<HTMLDivElement>(null);

    const [url, setUrl] = useState<string | undefined>();

    useEffect(() => {
        window.desktop.onSetURLForURLView((newUrl) => {
            setUrl(newUrl);
            window.desktop.updateURLViewWidth(urlRef.current?.scrollWidth);
        });
    }, []);

    if (url) {
        return (
            <div
                ref={urlRef}
                className='UrlView'
            >
                <p>{url}</p>
            </div>
        );
    }

    return null;
}
