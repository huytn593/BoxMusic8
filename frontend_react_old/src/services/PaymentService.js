const API_BASE = `${process.env.REACT_APP_API_BASE_URL}`;

export const getPaymentsUrl = async (data) => {
    try {
        const res = await fetch(`${API_BASE}/api/VnPay/create`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${localStorage.getItem('token')}`,
            },
            body: data
        });

        if (res.status === 403) {
            return "Phiên đăng nhập hết hạn";
        }

        if (res.status === 500 || res.status === 404) {
            return "Máy chủ đang bảo trì";
        }

        else if (res.status === 200) {
            return res.json();
        }
    }
    catch (err) {
        return err.message;
    }
};
