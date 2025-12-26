const API_BASE = `${process.env.REACT_APP_API_BASE_URL}`

export async function loginUser({ username, password }) {
    try {
        const response = await fetch(`${API_BASE}/api/Auth/login`, {
            method: 'POST',
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ username, password })
        });

        if (!response.ok) {
            return { success: false, status: response.status };
        }

        const result = await response.json();
        return {
            success: true,
            token: result.token,
            avatarBase64: result.avatarBase64
        };
    } catch (error) {
        return { success: false, error: 'network' };
    }
}

export const registerUser = async (values) => {
    const dob = `${values.dobYear}-${values.dobMonth.toString().padStart(2, '0')}-${values.dobDay.toString().padStart(2, '0')}`;

    const genderMap = {
        'Nam': 1,
        'Nữ': 2,
        'Khác': 3,
        'Không muốn trả lời': 4,
    };

    const payload = {
        username: values.username,
        fullname: values.fullName,
        email: values.email,
        password: values.password,
        phoneNumber: values.phone,
        dateOfBirth: dob,
        gender: genderMap[values.gender],
    };

    const response = await fetch(`${API_BASE}/api/Auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    });

    return response;
};

