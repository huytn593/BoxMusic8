import '../../styles/Footer.css';
import {
    FaPlay, FaPause, FaStepBackward, FaStepForward,
    FaVolumeMute, FaVolumeDown, FaVolumeUp, FaHeart, FaRedo
} from "react-icons/fa";
import React, { useEffect, useRef, useState } from "react";
import { useMusicPlayer } from '../../context/musicPlayerContext';
import { updateTrackPlayCount } from "../../services/trackService";
import { toast, ToastContainer } from "react-toastify";
import { useAuth } from "../../context/authContext";
import { checkUserIsFavorites, toggleFavorites } from "../../services/favoritesService";
import { useLoginSessionOut } from "../../services/loginSessionOut";
import { Button, Modal } from "react-bootstrap";
import { useNavigate } from "react-router-dom";
import { updateHistory } from "../../services/playHistoryService";

const Footer = () => {
    const audioRef = useRef(null);
    const progressRef = useRef(null);
    const { user, logout } = useAuth();
    const {
        playlist,
        currentTrack,
        currentTrackIndex,
        audioUrl,
        isPlaying,
        setIsPlaying,
        playTrackList,
    } = useMusicPlayer();

    const [progress, setProgress] = useState(0);
    const [currentTime, setCurrentTime] = useState(0);
    const [duration, setDuration] = useState(0);
    const [volume, setVolume] = useState(1);
    const [isReplay, setIsReplay] = useState(false);
    const [isLiked, setIsLiked] = useState(false);
    const [listenedTime, setListenedTime] = useState(0);

    const [showConfirmSigninModal, setShowConfirmSigninModal] = useState(false);
    const [showUpgradeModal, setShowUpgradeModal] = useState(false);

    const navigate = useNavigate();
    const isReplayRef = useRef(isReplay);
    const handleSessionOut = useLoginSessionOut();

    useEffect(() => {
        isReplayRef.current = isReplay;
    }, [isReplay]);

    const checkVipPermission = () => {
        const isVip = currentTrack?.isPublic === false;
        const hasPermission = user?.isLoggedIn && user.role !== "normal";

        if (!currentTrack || !isVip) return true;

        if (!user?.isLoggedIn) {
            setIsPlaying(false);
            setShowConfirmSigninModal(true);
            return false;
        }

        if (user.role === "normal") {
            setIsPlaying(false);
            setShowUpgradeModal(true);
            return false;
        }

        return true;
    };

    useEffect(() => {
        playTrackList([], 0)
        setIsPlaying(false);
        setIsLiked(false);
        setIsReplay(false);
    }, [user?.isLoggedIn]);

    useEffect(() => {
        if (!currentTrack || !currentTrack.id) return;

        const fetchFavoriteStatus = async () => {
            if (currentTrack?.id && user.isLoggedIn) {
                try {
                    const res = await checkUserIsFavorites(currentTrack.id);
                    if (res) {
                        setIsLiked(res.favorited);
                    } else {
                        toast.error("Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại", {
                            position: "top-center",
                            autoClose: 2000,
                            pauseOnHover: false,
                        });

                        setTimeout(() => {
                            logout();
                            navigate('/signin');
                            setIsPlaying(false);
                            playTrackList([], 0);
                        }, 2500);
                    }
                } catch (err) {
                    console.error("Lỗi khi kiểm tra yêu thích:", err);
                }
            }
        };

        fetchFavoriteStatus();
    }, [currentTrack?.id]);

    useEffect(() => {
        setCurrentTime(0);
        setListenedTime(0);
        setDuration(0);
    }, [currentTrack?.id]);

    useEffect(() => {
        if (!checkVipPermission()){
            setIsPlaying(false);
            return;
        }
        if (audioRef.current && audioUrl) {
            audioRef.current.load();
        }
    }, [audioUrl]);

    useEffect(() => {
        if (audioRef.current) {
            audioRef.current.volume = volume;
        }
    }, [volume]);

    const togglePlay = () => {
        if (!audioRef.current) return;
        if (!checkVipPermission()) return;

        if (isPlaying) {
            audioRef.current.pause();
            setIsPlaying(false);
        } else {
            audioRef.current.play()
                .then(() => setIsPlaying(true))
                .catch(err => console.error("Trình duyệt chặn phát audio:", err));
        }
    };

    const playNext = () => {
        if (playlist.length === 0 || playlist.length === 1) return;
        const nextIndex = (currentTrackIndex + 1) % playlist.length;
        playTrackList(playlist, nextIndex);
    };

    const playPrev = () => {
        if (playlist.length === 0 || playlist.length === 1) return;
        const prevIndex = (currentTrackIndex - 1 + playlist.length) % playlist.length;
        playTrackList(playlist, prevIndex);
    };

    const handleTimeUpdate = () => {
        const current = audioRef.current?.currentTime || 0;
        const dur = audioRef.current?.duration || 1;

        setListenedTime(prev => {
            const delta = current - currentTime;
            if (delta >= 0 && delta < 3) return prev + delta;
            return prev;
        });

        setCurrentTime(current);
        setDuration(dur);
        setProgress((current / dur) * 100);
    };

    const handleSeek = (e) => {
        if (!progressRef.current) return;
        const rect = progressRef.current.getBoundingClientRect();
        const offsetX = e.clientX - rect.left;
        const percentage = offsetX / rect.width;
        const seekTime = percentage * duration;
        if (audioRef.current) {
            audioRef.current.currentTime = seekTime;
        }
    };

    const handleReplay = () => {
        setIsReplay(prev => !prev);
    };

    const handleLike = async () => {
        if (user.isLoggedIn) {
            setIsLiked(prev => !prev);
            await toggleFavorites(currentTrack.id, handleSessionOut);
        } else {
            setShowConfirmSigninModal(true);
        }
    };

    const handleUpdateLastPlay = async (trackId) => {
        return await updateHistory(trackId);
    };

    const handleUpdateTrackPlayCount = async (id) => {
        try {
            await updateTrackPlayCount(id);
        } catch (err) {
            toast.error("Không thể kết nối đến máy chủ hiện tại", {
                position: "top-center",
                autoClose: 2000,
            });
        }
    };

    const formatTime = (time) => {
        if (isNaN(time)) return "0:00";
        const minutes = Math.floor(time / 60);
        const seconds = Math.floor(time % 60).toString().padStart(2, '0');
        return `${minutes}:${seconds}`;
    };

    const handleCloseModal = () => {
        if (currentTrack?.isPublic === false) {
            if (playlist.length > 1) {
                playNext();
                if (currentTrackIndex === playlist.length - 1) {
                    playTrackList([], 0);
                }
            } else {
                playTrackList([], 0);
            }
        }
        setShowUpgradeModal(false);
        setShowConfirmSigninModal(false);
    }

    return (
        <>
            {currentTrack && audioUrl && (
                <footer className="footer-player">
                    <div className="track-info">
                        <img src={currentTrack?.imageUrl || currentTrack?.coverImage || '/images/default-music.jpg'} alt="cover" />
                        <div>
                            <div className="title">{currentTrack?.title || "Chưa chọn bài hát nào"}</div>
                            <div className="subtitle">{currentTrack?.subtitle || currentTrack?.uploaderName || currentTrack?.artistName || ""}</div>
                        </div>
                    </div>

                    <div className="center-controls-horizontal">
                        <div className="control-buttons">
                            <button onClick={playPrev}><FaStepBackward /></button>
                            <button onClick={togglePlay} disabled={!audioUrl}>
                                {isPlaying ? <FaPause /> : <FaPlay />}
                            </button>
                            <button onClick={playNext}><FaStepForward /></button>
                        </div>

                        <div className="progress-wrapper" ref={progressRef} onClick={handleSeek}>
                            <div className="progress-time">
                                <span>{formatTime(currentTime)}</span>
                                <span>{formatTime(duration)}</span>
                            </div>
                            <div className="progress-bar-container">
                                <div className="progress-bar-fill" style={{ width: `${progress}%` }} />
                            </div>
                        </div>
                    </div>

                    <div className="volume-section">
                        <button
                            onClick={handleReplay}
                            className="replay-button"
                            style={{ color: isReplay ? "#ff4d4d" : "gray" }}
                        >
                            <FaRedo />
                        </button>
                        {volume === 0 ? <FaVolumeMute /> : volume < 0.5 ? <FaVolumeDown /> : <FaVolumeUp />}
                        <input
                            type="range"
                            min={0}
                            max={1}
                            step={0.01}
                            value={volume}
                            onChange={(e) => setVolume(parseFloat(e.target.value))}
                        />
                        <button
                            onClick={handleLike}
                            className={`like-button ${isLiked ? "active" : ""}`}
                        >
                            <FaHeart />
                        </button>
                    </div>

                    <audio
                        ref={audioRef}
                        preload="auto"
                        onEnded={() => {
                            if (currentTrack.id && listenedTime >= 0.9 * duration) {
                                handleUpdateTrackPlayCount(currentTrack.id);
                                handleUpdateLastPlay(currentTrack.id);
                            }

                            setListenedTime(0);

                            if (!checkVipPermission()) return;

                            if (isReplayRef.current) {
                                audioRef.current.currentTime = 0;
                                audioRef.current.play().catch(err => console.error("Không thể replay:", err));
                            } else {
                                setIsPlaying(false);
                                playNext();
                            }
                        }}
                        onTimeUpdate={handleTimeUpdate}
                        onCanPlay={() => {
                            if (!checkVipPermission()) {
                                audioRef.current.pause();
                                return;
                            }
                            if (isPlaying) {
                                audioRef.current.play().catch(err => console.warn("Autoplay bị chặn:", err));
                            }
                        }}
                    >
                        <source src={audioUrl} type="audio/mpeg" />
                        Trình duyệt không hỗ trợ phát audio.
                    </audio>
                </footer>
            )}

            <ToastContainer />

            <Modal show={showConfirmSigninModal} onHide={handleCloseModal} centered dialogClassName="custom-modal-overlay" backdrop={true}>
                <Modal.Header closeButton>
                    <Modal.Title>Cần phải đăng nhập</Modal.Title>
                </Modal.Header>
                <Modal.Body>Bạn có muốn đăng nhập để nghe và yêu thích bài hát này không?</Modal.Body>
                <Modal.Footer>
                    <Button variant="secondary" onClick={handleCloseModal}>Hủy</Button>
                    <Button variant="danger" onClick={() => {
                        setShowConfirmSigninModal(false);
                        setIsPlaying(false);
                        playTrackList([], 0);
                        navigate('/signin');
                    }}>Đăng nhập</Button>
                </Modal.Footer>
            </Modal>

            <Modal show={showUpgradeModal} onHide={handleCloseModal} centered dialogClassName="custom-modal-overlay" backdrop={true}>
                <Modal.Header closeButton>
                    <Modal.Title>Nâng cấp tài khoản</Modal.Title>
                </Modal.Header>
                <Modal.Body>
                    Bạn cần nâng cấp để nghe bài hát <strong>{currentTrack?.title}</strong>
                </Modal.Body>
                <Modal.Footer>
                    <Button variant="secondary" onClick={handleCloseModal}>Để sau</Button>
                    <Button variant="warning" onClick={() => {
                        setShowUpgradeModal(false);
                        playTrackList([], 0);
                        navigate(`/upgrade/${user.id}`);
                    }}>Nâng cấp ngay</Button>
                </Modal.Footer>
            </Modal>
        </>
    );
};

export default Footer;