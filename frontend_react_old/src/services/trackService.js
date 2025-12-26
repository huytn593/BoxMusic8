const API_BASE = `${process.env.REACT_APP_API_BASE_URL}`;

export const uploadTrack = async (formData, handleSessionOut) => {
    try {
        const res = await fetch(`${API_BASE}/api/Track/upload`, {
            method: 'POST',
            body: formData,
            headers: {
                'Authorization': 'Bearer ' + localStorage.getItem('token'),
            },
        });

        const data = await res.text();
        if (res.status === 401 || res.status === 403) {
            handleSessionOut();
        }
        if (!res.ok) throw new Error(data);
        return data;
    } catch (err) {
        throw err;
    }
};

export async function getTopTracks() {
    const res = await fetch(`${API_BASE}/api/Track/top-played`, {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
        }
    });

    if (res.status === 200) {
        return res.json();
    } else {
        return { success: false, status: res.status };
    }
}

export async function getTopLikeTracks() {
    const res = await fetch(`${API_BASE}/api/Track/top-like`, {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
        }
    });

    if (res.status === 200) {
        return res.json();
    } else {
        return { success: false, status: res.status };
    }
}

export const getTrackById = async (id) => {
    const res = await fetch(`${API_BASE}/api/Track/track-info/${id}`, {
        method: 'GET',
    });

    if (!res.ok) {
        throw new Error('Không tìm thấy bài hát.');
    }

    return await res.json();
};

export const updateTrackPlayCount = async (id) => {
    const res = await fetch(`${API_BASE}/api/Track/play-count/${id}`, {
        method: 'PUT',
    });

    if (!res.ok) {
        throw new Error('Có lỗi xảy ra.');
    }
}

export const getTrackDetail = async (trackId) => {
    const response = await fetch(`${API_BASE}/api/Track/track-detail/${trackId}`, {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
        }
    });
    if (!response.ok) {
        throw new Error(`Lỗi HTTP: ${response.status}`);
    }

    const data = await response.json();
    return data;
};

export const getTracksByArtistId = async (profileId) => {
    const res = await fetch(`${API_BASE}/api/Profile/my-tracks/${profileId}`);
    if (!res.ok) {
        throw new Error('Không thể lấy danh sách bài hát.');
    }
    return await res.json();
};

export const getAllTracks = async () => {
    const res = await fetch(`${API_BASE}/api/Track/all-track`, {
        method: 'GET',
        headers: {
            'Content-Type': 'application/json',
        }
    })

    if (res.status !== 200) {
        throw new Error("Lấy dữ liệu thất bại");
    }

    return res.json();
}

export const changeApprove = async (trackId) => {
    const res = await fetch(`${API_BASE}/api/Track/approve/${trackId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        }
    })

    if (res.status !== 200) {
        throw new Error("Cập nhật thất bại");
    }
}

export const changePublic = async (trackId) => {
    const res = await fetch(`${API_BASE}/api/Track/public/${trackId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        }
    })

    if (res.status !== 200) {
        throw new Error("Cập nhật thất bại");
    }
}

export const deleteTrack = async (trackId, handleSessionOut) => {
    const res = await fetch(`${API_BASE}/api/Track/delete/${trackId}`, {
        method: 'DELETE',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + localStorage.getItem('token'),
        }
    })

    if (res.status === 401 || res.status === 403) {
        handleSessionOut();
    } else if (!res.ok){
        throw new Error(res.statusText);
    }
}
