using backend;
using backend.Interfaces;
using backend.Models;
using backend.Repositories;
using backend.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MongoDB.Driver;
using StackExchange.Redis;
using System.IdentityModel.Tokens.Jwt;
using System.Text;
using System.Text.Json.Serialization;
using System.Diagnostics;
using Microsoft.Extensions.FileProviders;

void StartRedisIfNotRunning()
{
    var redisProcesses = Process.GetProcessesByName("redis-server");
    if (redisProcesses.Length == 0)
    {
        var redisPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Utils", "Caches", "redis-server.exe");

        if (!File.Exists(redisPath))
        {
            Console.WriteLine($"Redis executable not found at: {redisPath}");
            return;
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = redisPath,
            WorkingDirectory = Path.GetDirectoryName(redisPath),
            UseShellExecute = false,
            CreateNoWindow = true
        };

        try
        {
            Process.Start(startInfo);
            Console.WriteLine("Redis started from local folder.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Failed to start Redis: {ex.Message}");
        }
    }
    else
    {
        Console.WriteLine("Redis is already running.");
    }
}

var builder = WebApplication.CreateBuilder(args);

// Cấu hình MongoDB từ appsettings.json
builder.Services.Configure<MongoDbSettings>(
    builder.Configuration.GetSection("MongoDbSettings"));

builder.Services.AddSingleton<IMongoClient>(sp =>
{
    var settings = sp.GetRequiredService<IOptions<MongoDbSettings>>().Value;
    return new MongoClient(settings.ConnectionString);
});

builder.Services.AddScoped(serviceProvider =>
{
    var settings = serviceProvider.GetRequiredService<IOptions<MongoDbSettings>>().Value;
    var client = serviceProvider.GetRequiredService<IMongoClient>();
    return client.GetDatabase(settings.DatabaseName);
});

// Đăng ký Repository và Service
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUsersService, UsersService>();
builder.Services.AddScoped<IJWTService, JWTService>();
builder.Services.AddScoped<ITokenBlacklistService, RedisTokenBlacklistService>();
builder.Services.AddScoped<IVnPayService, VnPayService>();
builder.Services.AddScoped<ITrackRepository, TrackRepository>();
builder.Services.AddScoped<ITrackService, TrackService>();
builder.Services.AddScoped<IFavoritesRepository, FavoritesRepository>();
builder.Services.AddScoped<IFavoritesService, FavoritesService>();
builder.Services.AddScoped<IHistoryRepository, HistoryRepository>();
builder.Services.AddScoped<IHistoryService, HistoryService>();
builder.Services.AddScoped<ICommentRepository, CommentRepository>();
builder.Services.AddScoped<ICommentService, CommentService>();
builder.Services.AddScoped<IFollowersRepository, FollowersRepository>();
builder.Services.AddScoped<IFollowersService, FollowersService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();

// SignalR
builder.Services.AddSignalR();
builder.Services.AddScoped<ISearchService, SearchService>();
builder.Services.AddScoped<IPaymentRecordRepository, PaymentRecordRepository>();
builder.Services.AddScoped<IPaymentRecordService, PaymentRecordService>();
builder.Services.AddScoped<IPlaylistRepository, PlaylistRepository>();
builder.Services.AddScoped<IPlaylistService, PlaylistService>();
builder.Services.AddScoped<ITrackRecommendationService, TrackRecommendationService>();

//Redis cache
builder.Services.AddSingleton<IConnectionMultiplexer>(sp =>
{
    var configuration = builder.Configuration.GetValue<string>("Redis:ConnectionString");
    return ConnectionMultiplexer.Connect(configuration);
});

// Add Swagger và Controller
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "MusicBox backend API",
        Version = "1.0.0",
        Description = "API backend của website nghe nhạc MusicBox",
        Contact = new OpenApiContact
        {
            Name = "Trần Phạm Gia HuyHuy",
            Email = "huytn593@gmail.com"
        }
    });
});

var configuration = builder.Configuration;
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer("Bearer", options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,

            ValidIssuer = configuration["JWT:Issuer"],           
            ValidAudience = configuration["JWT:Audience"],      
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(configuration["JWT:Key"])),
            NameClaimType = JwtRegisteredClaimNames.Sub,
            RoleClaimType = "role"
        };

        options.Events = new JwtBearerEvents
        {
            OnAuthenticationFailed = context =>
            {
                // Không tự set status code ở đây, để framework xử lý
                // Chỉ log lỗi nếu cần
                return Task.CompletedTask;
            },

            OnChallenge = context =>
            {
                // Xử lý challenge event - đảm bảo không set status code nếu response đã bắt đầu
                // Nếu response đã bắt đầu, không làm gì cả
                if (context.Response.HasStarted)
                {
                    return Task.CompletedTask;
                }
                
                // Để framework tự xử lý challenge (sẽ set 401)
                // Không gọi HandleResponse() để tránh conflict
                return Task.CompletedTask;
            },

            OnTokenValidated = async context =>
            {
                // Chỉ validate nếu response chưa bắt đầu
                if (context.Response.HasStarted)
                {
                    return;
                }

                var tokenBlacklistService = context.HttpContext.RequestServices.GetRequiredService<ITokenBlacklistService>();

                var jti = context.Principal?.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Jti)?.Value;

                if (string.IsNullOrEmpty(jti))
                {
                    context.Fail("Token does not contain jti");
                    return;
                }

                var isBlacklisted = await tokenBlacklistService.IsBlacklistedAsync(jti);

                if (isBlacklisted)
                {
                    context.Fail("Token is blacklisted");
                }
            }
        };
    });

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend",
        policy =>
        {
            policy.WithOrigins("http://localhost:3000")
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        });
});


builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder =>
        {
            builder.AllowAnyOrigin()
                   .AllowAnyHeader()
                   .AllowAnyMethod();
        });
});

builder.Services.AddControllers().AddJsonOptions(options =>
{
    options.JsonSerializerOptions.TypeInfoResolver = JsonContext.Default;
});

StartRedisIfNotRunning();

var app = builder.Build();

// CORS phải được đặt trước tất cả middleware khác
app.UseCors("AllowAll");

// Routing phải được map trước Swagger
app.UseRouting();

if (app.Environment.IsDevelopment())
{
    // Swagger chỉ xử lý Swagger endpoints, không can thiệp vào API
    // Sử dụng MapWhen để chỉ enable Swagger cho /swagger routes
    app.MapWhen(
        context => context.Request.Path.StartsWithSegments("/swagger"),
        appBuilder =>
        {
            appBuilder.UseSwagger(c =>
            {
                c.RouteTemplate = "swagger/{documentName}/swagger.json";
            });
            appBuilder.UseSwaggerUI(c =>
            {
                c.SwaggerEndpoint("/swagger/v1/swagger.json", "MusicBox API v1");
                c.RoutePrefix = "swagger";
            });
        });
}

app.UseAuthentication();
app.UseAuthorization();

// Static files chỉ xử lý các routes cụ thể, không can thiệp vào API
// Phải được map trước MapControllers để không can thiệp vào API routes
app.MapWhen(
    context => context.Request.Path.StartsWithSegments("/cover_images"),
    appBuilder =>
    {
        appBuilder.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = new PhysicalFileProvider(
                Path.Combine(Directory.GetCurrentDirectory(), "storage", "cover_images")),
            RequestPath = "/cover_images"
        });
    });

app.MapWhen(
    context => context.Request.Path.StartsWithSegments("/avatar"),
    appBuilder =>
    {
        appBuilder.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = new PhysicalFileProvider(
                Path.Combine(Directory.GetCurrentDirectory(), "storage", "avatar")),
            RequestPath = "/avatar"
        });
    });

app.MapWhen(
    context => context.Request.Path.StartsWithSegments("/playlist_cover"),
    appBuilder =>
    {
        appBuilder.UseStaticFiles(new StaticFileOptions
        {
            FileProvider = new PhysicalFileProvider(
                Path.Combine(Directory.GetCurrentDirectory(), "storage", "playlist_cover")),
            RequestPath = "/playlist_cover"
        });
    });

// Map route cho controller - phải được map sau static files
app.MapControllers();

// Map SignalR Hub
app.MapHub<backend.Hubs.NotificationHub>("/notificationHub");

app.Run();
