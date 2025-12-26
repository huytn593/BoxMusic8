import { toast } from "react-toastify";
import { useAuth } from "../context/authContext";
import { useNavigate } from "react-router-dom";

export function useLoginSessionOut() {
    const { logout } = useAuth();
    const navigate = useNavigate();

    const handleSessionOut = () => {
        toast.error("Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại", {
            position: "top-center",
            autoClose: 2000,
            pauseOnHover: false,
        });

        setTimeout(() => {
            logout();
            navigate('/signin');
        }, 2500);
    };

    return handleSessionOut;
}
