using backend.Controllers;
using backend.DTOs;
using backend.Models;
using Microsoft.AspNetCore.Mvc;
using System.Text.Json.Serialization;

namespace backend
{
    [JsonSerializable(typeof(LoginRequest))]
    [JsonSerializable(typeof(LoginResponse))]
    [JsonSerializable(typeof(RegisterRequest))]
    [JsonSerializable(typeof(RegisterResponse))]
    [JsonSerializable(typeof(GetProfileDataResponse))]
    [JsonSerializable(typeof(PersonalRequest))]
    [JsonSerializable(typeof(PaymentInformationModel))]
    [JsonSerializable(typeof(PaymentResponseModel))]
    [JsonSerializable(typeof(PaymentUrlResponse))]
    [JsonSerializable(typeof(UploadTrackRequest))]
    [JsonSerializable(typeof(UploadTrackResponse))]
    [JsonSerializable(typeof(TrackDetail))]
    [JsonSerializable(typeof(SendOtpRequest))]
    [JsonSerializable(typeof(VerifyOtpRequest))]
    [JsonSerializable(typeof(ResetPasswordRequest))]
    [JsonSerializable(typeof(List<TrackAdminView>))]
    [JsonSerializable(typeof(List<CommentDetail>))]
    [JsonSerializable(typeof(AddCommentRequest))]
    [JsonSerializable(typeof(Dictionary<string, string>))]
    [JsonSerializable(typeof(List<TrackThumbnail>))]
    [JsonSerializable(typeof(ProblemDetails))]
    [JsonSerializable(typeof(ValidationProblemDetails))]
    [JsonSerializable(typeof(ApiResponse))]
    [JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
    [JsonSerializable(typeof(FavoriteCheckResponse))]
    [JsonSerializable(typeof(FavoriteToggleResponse))]
    [JsonSerializable(typeof(SearchResultDto))]
    [JsonSerializable(typeof(TrackSearchDto))]
    [JsonSerializable(typeof(List<FavoriteTracksResponse>))]
    [JsonSerializable(typeof(List<HistoryTrackResponse>))]
    [JsonSerializable(typeof(List<NotificationDto>))]
    [JsonSerializable(typeof(List<TrackInfo>))]
    [JsonSerializable(typeof(List<TrackListItemDto>))]
    [JsonSerializable(typeof(UserTracksResponse))]
    [JsonSerializable(typeof(FollowCheckResponse))]
    [JsonSerializable(typeof(FollowingListResponse))]
    [JsonSerializable(typeof(List<PaymentRecord>))]
    [JsonSerializable(typeof(PublicProfileDataDto))]
    [JsonSerializable(typeof(List<PlaylistDto>))]
    [JsonSerializable(typeof(PlaylistDto))]
    [JsonSerializable(typeof(PlaylistDetailDto))]
    [JsonSerializable(typeof(UserPlaylistLimits))]
    [JsonSerializable(typeof(CreatePlaylistRequest))]
    [JsonSerializable(typeof(UpdatePlaylistRequest))]
    [JsonSerializable(typeof(AddTrackToPlaylistRequest))]
    [JsonSerializable(typeof(PlaylistTrackDto))]
    [JsonSerializable(typeof(ErrorResponse))]
    [JsonSerializable(typeof(MessageResponse))]
    [JsonSerializable(typeof(FollowingDetailsListResponse))]
    [JsonSerializable(typeof(FollowingDetailsResponse))]
    [JsonSerializable(typeof(VerifyEmailOtpRequest))]
    [JsonSerializable(typeof(ChangePasswordRequest))]
    [JsonSerializable(typeof(UpdateAddressRequest))]

    public partial class JsonContext : JsonSerializerContext
    {
    }
}
