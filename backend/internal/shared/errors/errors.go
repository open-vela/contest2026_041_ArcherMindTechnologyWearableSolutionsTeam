package errors

import (
	"errors"
	"fmt"
	"net/http"
)

// AppError 统一业务错误
type AppError struct {
	Code       int    `json:"code"`
	Message    string `json:"message"`
	HTTPStatus int    `json:"-"`
	Err        error  `json:"-"`
}

func (e *AppError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("[%d] %s: %v", e.Code, e.Message, e.Err)
	}
	return fmt.Sprintf("[%d] %s", e.Code, e.Message)
}

func (e *AppError) Unwrap() error {
	return e.Err
}

// 预定义错误码
const (
	// 通用 10000-10099
	ErrCodeInternal       = 10001
	ErrCodeBadRequest     = 10002
	ErrCodeUnauthorized   = 10003
	ErrCodeForbidden      = 10004
	ErrCodeNotFound       = 10005
	ErrCodeConflict       = 10006
	ErrCodeTooManyRequest = 10007
	ErrCodeValidation     = 10008

	// 认证 10100-10199
	ErrCodeInvalidCredential = 10101
	ErrCodeTokenExpired      = 10102
	ErrCodeTokenInvalid      = 10103
	ErrCodeAccountLocked     = 10104
	ErrCodeAccountDisabled   = 10105
	ErrCodePasswordExpired   = 10106
	ErrCodeMFARequired       = 10107
	ErrCodeMFAFailed         = 10108
	ErrCodeIPNotAllowed      = 10109
	ErrCodeWeakPassword      = 10110

	// 用户 10200-10299
	ErrCodeUserNotFound     = 10201
	ErrCodeUserAlreadyExist = 10202

	// 设备 10300-10399
	ErrCodeDeviceNotFound     = 10301
	ErrCodeDeviceOffline      = 10302
	ErrCodeDeviceAlreadyBound = 10303
	ErrCodeDeviceNotRegistered = 10304

	// 报警 10400-10499
	ErrCodeAlarmNotFound   = 10401
	ErrCodeAlarmHandled    = 10402
	ErrCodeNoPermission    = 10403

	// 签到 10500-10599
	ErrCodeSigninWindowClosed  = 10501
	ErrCodeAlreadyCheckedIn    = 10502
	ErrCodeProxyNotAllowed     = 10503

	// 巡访 10600-10699
	ErrCodePatrolTaskNotFound  = 10601
	ErrCodeStaffNotAvailable   = 10602

	// 管理员 10700-10799
	ErrCodeAdminNotFound       = 10701
	ErrCodeRoleNotFound        = 10702
	ErrCodePermissionDenied    = 10703
	ErrCodeCantDeleteSelf      = 10704
	ErrCodeCantLockSelf        = 10705
	ErrCodeSystemRoleCantDelete = 10706
)

// 预定义错误实例
var (
	ErrInternal       = &AppError{Code: ErrCodeInternal, Message: "服务器内部错误", HTTPStatus: http.StatusInternalServerError}
	ErrUnauthorized   = &AppError{Code: ErrCodeUnauthorized, Message: "未授权访问", HTTPStatus: http.StatusUnauthorized}
	ErrForbidden      = &AppError{Code: ErrCodeForbidden, Message: "无权限访问", HTTPStatus: http.StatusForbidden}
	ErrNotFound       = &AppError{Code: ErrCodeNotFound, Message: "资源不存在", HTTPStatus: http.StatusNotFound}
	ErrBadRequest     = &AppError{Code: ErrCodeBadRequest, Message: "请求参数错误", HTTPStatus: http.StatusBadRequest}
	ErrConflict       = &AppError{Code: ErrCodeConflict, Message: "资源冲突", HTTPStatus: http.StatusConflict}
	ErrTooManyRequest = &AppError{Code: ErrCodeTooManyRequest, Message: "请求过于频繁", HTTPStatus: http.StatusTooManyRequests}
	ErrValidation     = &AppError{Code: ErrCodeValidation, Message: "参数校验失败", HTTPStatus: http.StatusBadRequest}
)

// New 创建新的业务错误
func New(code int, message string) *AppError {
	return &AppError{Code: code, Message: message, HTTPStatus: http.StatusBadRequest}
}

// Newf 格式化创建
func Newf(code int, format string, args ...interface{}) *AppError {
	return &AppError{Code: code, Message: fmt.Sprintf(format, args...), HTTPStatus: http.StatusBadRequest}
}

// Wrap 包装错误
func Wrap(code int, message string, err error) *AppError {
	return &AppError{Code: code, Message: message, HTTPStatus: http.StatusInternalServerError, Err: err}
}

// WithStatus 设置 HTTP 状态码
func (e *AppError) WithStatus(status int) *AppError {
	e.HTTPStatus = status
	return e
}

// Is 判断错误码
func IsAppError(err error, code int) bool {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr.Code == code
	}
	return false
}

// GetAppError 从 error 中提取 AppError
func GetAppError(err error) *AppError {
	var appErr *AppError
	if errors.As(err, &appErr) {
		return appErr
	}
	return ErrInternal
}
