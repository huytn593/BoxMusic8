using backend.Controllers;
using backend.Interfaces;
using backend.Models;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.IO;
using backend.DTOs;

namespace backend.Services
{
    public class FavoritesService : IFavoritesService
    {
        private readonly IFavoritesRepository _favoritesRepository;
        private readonly ITrackRepository _trackRepository;

        public FavoritesService(IFavoritesRepository favoritesRepository, ITrackRepository trackRepository)
        {
            _favoritesRepository = favoritesRepository;
            _trackRepository = trackRepository;
        }

        public async Task<bool> ToggleFavoriteAsync(string userId, string trackId)
        {
            var isFavorited = await _favoritesRepository.IsFavoriteAsync(userId, trackId);

            if (isFavorited)
            {
                await _favoritesRepository.RemoveFavoriteAsync(userId, trackId);
                await _trackRepository.DecreaseLikeCountAsync(trackId);
                return false;
            }
            else
            {
                var favorite = new Favorites
                {
                    UserId = userId,
                    TrackId = trackId
                };

                await _favoritesRepository.AddFavoriteAsync(favorite);
                await _trackRepository.IncreaseLikeCountAsync(trackId);
                return true; // đã like
            }
        }

        public async Task<List<FavoriteTracksResponse>> GetFavoriteTrackByUserAsync(string userId)
        {
            var tracksId = await _favoritesRepository.GetFavoriteTrackIdsByUserAsync(userId);
            List<FavoriteTracksResponse> tracks = new List<FavoriteTracksResponse>();
            foreach (var trackId in tracksId)
            {
                var track = await _trackRepository.GetByIdAsync(trackId);
                string? base64Image = !string.IsNullOrEmpty(track.Cover)
                    ? $"http://localhost:5270/cover_images/{track.Cover}"
                    : null;

                tracks.Add(new FavoriteTracksResponse
                {
                    trackId = track.Id,
                    title = track.Title,
                    isPublic = track.IsPublic,
                    cover = track.Cover,
                    filename = track.Filename,
                    artistId = track.ArtistId,
                    imageBase64 = base64Image,
                });
            }
            return tracks;                
        }

        public async Task<bool> IsTrackFavoritedAsync(string userId, string trackId)
        {
            return await _favoritesRepository.IsFavoriteAsync(userId, trackId);
        }

        public async Task<int> GetTrackFavoriteCountAsync(string trackId)
        {
            return await _favoritesRepository.GetFavoriteCountByTrackAsync(trackId);
        }

        public async Task DeleteAllFavoritesAsync(string userId)
        {
            var trackIds = await _favoritesRepository.GetFavoriteTrackIdsByUserAsync(userId);
            await _favoritesRepository.DeleteAllFavoritesByUserAsync(userId);
            foreach (var trackId in trackIds)
            {
                await _trackRepository.DecreaseLikeCountAsync(trackId);
            }
        }
    }
}
