// Copyright 2021 Dolthub, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package tiny_parser

import (
	"fmt"
	"strconv"
	"strings"
)

// AccountName represents either a user or role name, which has the format `name`@`host`.
type AccountName struct {
	Name    string
	Host    string
	AnyHost bool
}

// String returns the AccountName as a formatted string.
func (an *AccountName) String() string {
	host := an.Host
	if an.AnyHost {
		host = "%"
	}
	return fmt.Sprintf("`%s`@`%s`",
		strings.ReplaceAll(an.Name, "`", "``"), strings.ReplaceAll(host, "`", "``"))
}

// IsEmpty returns true if any of the fields in this AccountName are set.
func (an *AccountName) IsEmpty() bool {
	return an.Name == "" && an.Host == ""
}

// AccountRename represents an account changing its name.
type AccountRename struct {
	From AccountName
	To   AccountName
}

// String returns the AccountRename as a formatted string.
func (ar *AccountRename) String() string {
	return fmt.Sprintf("%s to %s", ar.From.String(), ar.To.String())
}

// Authentication represents an account's authentication.
type Authentication struct {
	RandomPassword bool
	Password       string
	Identity       string
	Plugin         string
}

// String returns this Authentication as a formatted string.
func (auth *Authentication) String() string {
	if len(auth.Plugin) > 0 {
		if len(auth.Password) > 0 {
			return fmt.Sprintf("identified with %s by '%s'", auth.Plugin, auth.Password)
		} else if auth.RandomPassword {
			return fmt.Sprintf("identified with %s by random password", auth.Plugin)
		} else if len(auth.Identity) > 0 {
			return fmt.Sprintf("identified with %s as '%s'", auth.Plugin, auth.Identity)
		} else {
			return fmt.Sprintf("identified with %s", auth.Plugin)
		}
	} else if auth.RandomPassword {
		return "identified by random password"
	} else {
		return fmt.Sprintf("identified by '%s'", auth.Password)
	}
}

// AccountWithAuth represents a new account with all of its authentication information.
type AccountWithAuth struct {
	AccountName
	Auth1       *Authentication
	Auth2       *Authentication
	Auth3       *Authentication
	AuthInitial *Authentication
}

// String returns AccountWithAuth as a formatted string.
func (awa *AccountWithAuth) String() string {
	sb := strings.Builder{}
	sb.WriteString(awa.AccountName.String())
	if awa.Auth1 != nil {
		sb.WriteRune(' ')
		sb.WriteString(awa.Auth1.String())
		if awa.AuthInitial != nil {
			sb.WriteString(" initial authentication ")
			sb.WriteString(awa.AuthInitial.String())
		} else if awa.Auth2 != nil {
			sb.WriteString(" and ")
			sb.WriteString(awa.Auth2.String())
			if awa.Auth3 != nil {
				sb.WriteString(" and ")
				sb.WriteString(awa.Auth3.String())
			}
		}
	}
	return sb.String()
}

// TLSOptionItemType defines the type that a TLSOptionItem represents.
type TLSOptionItemType byte

const (
	TLSOptionItemType_SSL TLSOptionItemType = iota
	TLSOptionItemType_X509
	TLSOptionItemType_Cipher
	TLSOptionItemType_Issuer
	TLSOptionItemType_Subject
)

// TLSOptionItem represents one of the available TLS options.
type TLSOptionItem struct {
	TLSOptionItemType
	ItemData string
}

// TLSOptions represents a new user's TLS options.
type TLSOptions struct {
	SSL     bool
	X509    bool
	Cipher  string
	Issuer  string
	Subject string
}

// NewTLSOptions returns a new TLSOptions from the given items.
func NewTLSOptions(items []TLSOptionItem) (*TLSOptions, error) {
	if len(items) == 0 {
		return nil, nil
	}
	options := &TLSOptions{}
	for _, item := range items {
		// Some combinations are allowed while others are not, which is not reflected in MySQL's grammar, and was
		// accidentally discovered when verifying that written tests are correct.
		switch item.TLSOptionItemType {
		case TLSOptionItemType_SSL:
			if options.SSL || options.X509 || len(options.Cipher) > 0 || len(options.Issuer) > 0 || len(options.Subject) > 0 {
				return nil, fmt.Errorf("invalid tls options")
			}
			options.SSL = true
		case TLSOptionItemType_X509:
			if options.SSL || options.X509 || len(options.Cipher) > 0 || len(options.Issuer) > 0 || len(options.Subject) > 0 {
				return nil, fmt.Errorf("invalid tls options")
			}
			options.X509 = true
		case TLSOptionItemType_Cipher:
			if options.SSL || options.X509 || len(options.Cipher) > 0 {
				return nil, fmt.Errorf("invalid tls options")
			}
			options.Cipher = item.ItemData
		case TLSOptionItemType_Issuer:
			if options.SSL || options.X509 || len(options.Issuer) > 0 {
				return nil, fmt.Errorf("invalid tls options")
			}
			options.Issuer = item.ItemData
		case TLSOptionItemType_Subject:
			if options.SSL || options.X509 || len(options.Subject) > 0 {
				return nil, fmt.Errorf("invalid tls options")
			}
			options.Subject = item.ItemData
		}
	}
	return options, nil
}

// String returns the TLSOptions as a formatted string.
func (tls *TLSOptions) String() string {
	var options []string
	if tls.SSL {
		options = append(options, "SSL")
	}
	if tls.X509 {
		options = append(options, "X509")
	}
	if len(tls.Cipher) > 0 {
		options = append(options, fmt.Sprintf("cipher '%s'", tls.Cipher))
	}
	if len(tls.Issuer) > 0 {
		options = append(options, fmt.Sprintf("issuer '%s'", tls.Issuer))
	}
	if len(tls.Subject) > 0 {
		options = append(options, fmt.Sprintf("subject '%s'", tls.Subject))
	}
	return strings.Join(options, " and ")
}

// AccountLimitItemType defines the type that an AccountLimitItem represents.
type AccountLimitItemType byte

const (
	AccountLimitItemType_Queries_PH AccountLimitItemType = iota
	AccountLimitItemType_Updates_PH
	AccountLimitItemType_Connections_PH
	AccountLimitItemType_Connections
)

// AccountLimitItem represents one of the available account limitations.
type AccountLimitItem struct {
	AccountLimitItemType
	Count *SQLVal
}

// AccountLimits represents a new user's maximum limits.
type AccountLimits struct {
	MaxQueriesPerHour     *SQLVal
	MaxUpdatesPerHour     *SQLVal
	MaxConnectionsPerHour *SQLVal
	MaxUserConnections    *SQLVal
}

// NewAccountLimits returns a new AccountLimits from the given items.
func NewAccountLimits(items []AccountLimitItem) (*AccountLimits, error) {
	if len(items) == 0 {
		return nil, nil
	}
	limits := &AccountLimits{}
	for _, item := range items {
		// Duplicates are allowed, the last instance seen is the one that sticks.
		switch item.AccountLimitItemType {
		case AccountLimitItemType_Queries_PH:
			limits.MaxQueriesPerHour = item.Count
		case AccountLimitItemType_Updates_PH:
			limits.MaxUpdatesPerHour = item.Count
		case AccountLimitItemType_Connections_PH:
			limits.MaxConnectionsPerHour = item.Count
		case AccountLimitItemType_Connections:
			limits.MaxUserConnections = item.Count
		}
	}
	return limits, nil
}

// String returns the AccountLimits as a formatted string.
func (al *AccountLimits) String() string {
	var limits []string
	if atoi(al.MaxQueriesPerHour) > 0 {
		limits = append(limits, fmt.Sprintf("max_queries_per_hour %d", atoi(al.MaxQueriesPerHour)))
	}
	if atoi(al.MaxUpdatesPerHour) > 0 {
		limits = append(limits, fmt.Sprintf("max_updates_per_hour %d", atoi(al.MaxUpdatesPerHour)))
	}
	if atoi(al.MaxConnectionsPerHour) > 0 {
		limits = append(limits, fmt.Sprintf("max_connections_per_hour %d", atoi(al.MaxConnectionsPerHour)))
	}
	if atoi(al.MaxUserConnections) > 0 {
		limits = append(limits, fmt.Sprintf("max_user_connections %d", atoi(al.MaxUserConnections)))
	}
	return strings.Join(limits, " ")
}

// PassLockItemType defines the type that a PassLockItem represents.
type PassLockItemType byte

const (
	PassLockItemType_PassExpireDefault PassLockItemType = iota
	PassLockItemType_PassExpireNever
	PassLockItemType_PassExpireInterval
	PassLockItemType_PassHistory
	PassLockItemType_PassReuseInterval
	PassLockItemType_PassReqCurrentDefault
	PassLockItemType_PassReqCurrentOptional
	PassLockItemType_PassFailedLogins
	PassLockItemType_PassLockTime
	PassLockItemType_AccountLock
	PassLockItemType_AccountUnlock
)

// PassLockItem represents one of the available password or account options.
type PassLockItem struct {
	PassLockItemType
	Value *SQLVal
}

// PasswordOptions represents which options may be given to new user account on how to handle passwords.
type PasswordOptions struct {
	RequireCurrentOptional bool

	ExpirationTime *SQLVal // nil represents the default
	History        *SQLVal // nil represents the default
	ReuseInterval  *SQLVal // nil represents the default
	FailedAttempts *SQLVal // will always be set
	LockTime       *SQLVal // nil represents an unbounded lock time
}

// NewPasswordOptionsWithLock returns a new PasswordOptions, along with whether to lock the account, from the given items.
func NewPasswordOptionsWithLock(items []PassLockItem) (*PasswordOptions, bool) {
	if len(items) == 0 {
		return nil, false
	}
	options := &PasswordOptions{
		FailedAttempts: NewIntVal([]byte("0")),
		LockTime:       NewIntVal([]byte("0")),
	}
	accountLock := false
	for _, item := range items {
		// Duplicates are allowed, the last instance seen is the one that sticks.
		switch item.PassLockItemType {
		case PassLockItemType_PassExpireDefault:
			options.ExpirationTime = nil
		case PassLockItemType_PassExpireNever:
			options.ExpirationTime = NewIntVal([]byte("0"))
		case PassLockItemType_PassExpireInterval:
			options.ExpirationTime = item.Value
		case PassLockItemType_PassHistory:
			options.History = item.Value
		case PassLockItemType_PassReuseInterval:
			options.ReuseInterval = item.Value
		case PassLockItemType_PassReqCurrentDefault:
			options.RequireCurrentOptional = false
		case PassLockItemType_PassReqCurrentOptional:
			options.RequireCurrentOptional = true
		case PassLockItemType_PassFailedLogins:
			options.FailedAttempts = item.Value
		case PassLockItemType_PassLockTime:
			options.LockTime = item.Value
		case PassLockItemType_AccountLock:
			accountLock = true
		case PassLockItemType_AccountUnlock:
			accountLock = false
		}
	}
	return options, accountLock
}

// String returns PasswordOptions as a formatted string.
func (po *PasswordOptions) String() string {
	var options []string
	if po.ExpirationTime != nil {
		if atoi(po.ExpirationTime) == 0 {
			options = append(options, "password expire never")
		} else {
			options = append(options, fmt.Sprintf("password expire interval %d day", atoi(po.ExpirationTime)))
		}
	}
	if po.History != nil {
		options = append(options, fmt.Sprintf("password history %d", atoi(po.History)))
	}
	if po.ReuseInterval != nil {
		options = append(options, fmt.Sprintf("password reuse interval %d day", atoi(po.ReuseInterval)))
	}
	if po.RequireCurrentOptional {
		options = append(options, "password require current optional")
	}
	if atoi(po.FailedAttempts) > 0 {
		options = append(options, fmt.Sprintf("failed_login_attempts %d", atoi(po.FailedAttempts)))
	}
	if po.LockTime == nil {
		options = append(options, "password_lock_time unbounded")
	} else if atoi(po.LockTime) > 0 {
		options = append(options, fmt.Sprintf("password_lock_time %d", atoi(po.LockTime)))
	}
	return strings.Join(options, " ")
}

// PrivilegeType is the type of privilege that is being granted or revoked.
type PrivilegeType byte

const (
	PrivilegeType_All PrivilegeType = iota
	PrivilegeType_Alter
	PrivilegeType_AlterRoutine
	PrivilegeType_Create
	PrivilegeType_CreateRole
	PrivilegeType_CreateRoutine
	PrivilegeType_CreateTablespace
	PrivilegeType_CreateTemporaryTables
	PrivilegeType_CreateUser
	PrivilegeType_CreateView
	PrivilegeType_Delete
	PrivilegeType_Drop
	PrivilegeType_DropRole
	PrivilegeType_Event
	PrivilegeType_Execute
	PrivilegeType_File
	PrivilegeType_GrantOption
	PrivilegeType_Index
	PrivilegeType_Insert
	PrivilegeType_LockTables
	PrivilegeType_Process
	PrivilegeType_References
	PrivilegeType_Reload
	PrivilegeType_ReplicationClient
	PrivilegeType_ReplicationSlave
	PrivilegeType_Select
	PrivilegeType_ShowDatabases
	PrivilegeType_ShowView
	PrivilegeType_Shutdown
	PrivilegeType_Super
	PrivilegeType_Trigger
	PrivilegeType_Update
	PrivilegeType_Usage
	PrivilegeType_Dynamic // Dynamic privileges are defined at runtime, rather than enforced at the parser
	//TODO: add the rest of the privileges -> https://dev.mysql.com/doc/refman/8.0/en/privileges-provided.html
)

// GrantObjectType represents the object type that the GRANT or REVOKE statement will apply to.
type GrantObjectType byte

const (
	GrantObjectType_Any GrantObjectType = iota
	GrantObjectType_Table
	GrantObjectType_Function
	GrantObjectType_Procedure
)

// GrantUserAssumptionType is the assumption type that the user executing the GRANT statement will use.
type GrantUserAssumptionType byte

const (
	GrantUserAssumptionType_Default GrantUserAssumptionType = iota
	GrantUserAssumptionType_None
	GrantUserAssumptionType_All
	GrantUserAssumptionType_AllExcept
	GrantUserAssumptionType_Roles
)

// PrivilegeLevel defines the level that a privilege applies to.
type PrivilegeLevel struct {
	Database     string
	TableRoutine string
}

// String returns the PrivilegeLevel as a formatted string.
func (p *PrivilegeLevel) String() string {
	if p.Database == "" {
		if p.TableRoutine == "*" {
			return "*"
		} else {
			return fmt.Sprintf("`%s`", p.TableRoutine)
		}
	} else if p.Database == "*" {
		return "*.*"
	} else if p.TableRoutine == "*" {
		return fmt.Sprintf("`%s`.*", p.Database)
	} else {
		return fmt.Sprintf("`%s`.`%s`", p.Database, p.TableRoutine)
	}
}

// Privilege specifies a privilege to be used in a GRANT or REVOKE statement.
type Privilege struct {
	Type        PrivilegeType
	DynamicName string
	Columns     []string
}

// String returns the Privilege as a formatted string.
func (p *Privilege) String() string {
	sb := strings.Builder{}
	switch p.Type {
	case PrivilegeType_All:
		sb.WriteString("all")
	case PrivilegeType_Alter:
		sb.WriteString("alter")
	case PrivilegeType_AlterRoutine:
		sb.WriteString("alter routine")
	case PrivilegeType_Create:
		sb.WriteString("create")
	case PrivilegeType_CreateRole:
		sb.WriteString("create role")
	case PrivilegeType_CreateRoutine:
		sb.WriteString("create routine")
	case PrivilegeType_CreateTablespace:
		sb.WriteString("create tablespace")
	case PrivilegeType_CreateTemporaryTables:
		sb.WriteString("create temporary tables")
	case PrivilegeType_CreateUser:
		sb.WriteString("create user")
	case PrivilegeType_CreateView:
		sb.WriteString("create view")
	case PrivilegeType_Delete:
		sb.WriteString("delete")
	case PrivilegeType_Drop:
		sb.WriteString("drop")
	case PrivilegeType_DropRole:
		sb.WriteString("drop role")
	case PrivilegeType_Event:
		sb.WriteString("event")
	case PrivilegeType_Execute:
		sb.WriteString("execute")
	case PrivilegeType_File:
		sb.WriteString("file")
	case PrivilegeType_GrantOption:
		sb.WriteString("grant option")
	case PrivilegeType_Index:
		sb.WriteString("index")
	case PrivilegeType_Insert:
		sb.WriteString("insert")
	case PrivilegeType_LockTables:
		sb.WriteString("lock tables")
	case PrivilegeType_Process:
		sb.WriteString("process")
	case PrivilegeType_References:
		sb.WriteString("references")
	case PrivilegeType_Reload:
		sb.WriteString("reload")
	case PrivilegeType_ReplicationClient:
		sb.WriteString("replication client")
	case PrivilegeType_ReplicationSlave:
		sb.WriteString("replication slave")
	case PrivilegeType_Select:
		sb.WriteString("select")
	case PrivilegeType_ShowDatabases:
		sb.WriteString("show databases")
	case PrivilegeType_ShowView:
		sb.WriteString("show view")
	case PrivilegeType_Shutdown:
		sb.WriteString("shutdown")
	case PrivilegeType_Super:
		sb.WriteString("super")
	case PrivilegeType_Trigger:
		sb.WriteString("trigger")
	case PrivilegeType_Update:
		sb.WriteString("update")
	case PrivilegeType_Usage:
		sb.WriteString("usage")
	case PrivilegeType_Dynamic:
		sb.WriteString(p.DynamicName)
	}
	if len(p.Columns) > 0 {
		sb.WriteString(" (`")
		for i, col := range p.Columns {
			if i > 0 {
				sb.WriteString("`, `")
			}
			sb.WriteString(col)
		}
		sb.WriteString("`)")
	}
	return sb.String()
}

// GrantUserAssumption represents the target user that the user executing the GRANT statement will assume the identity of.
type GrantUserAssumption struct {
	Type  GrantUserAssumptionType
	User  AccountName
	Roles []AccountName
}

// String returns this GrantUserAssumption as a formatted string.
func (gau *GrantUserAssumption) String() string {
	sb := strings.Builder{}
	sb.WriteString("as ")
	sb.WriteString(gau.User.String())
	switch gau.Type {
	case GrantUserAssumptionType_Default:
		// Do nothing, here to explicitly list all cases
	case GrantUserAssumptionType_None:
		sb.WriteString(" with role none")
	case GrantUserAssumptionType_All:
		sb.WriteString(" with role all")
	case GrantUserAssumptionType_AllExcept:
		sb.WriteString(" with role all except")
		for i, role := range gau.Roles {
			if i > 0 {
				sb.WriteRune(',')
			}
			sb.WriteRune(' ')
			sb.WriteString(role.String())
		}
	case GrantUserAssumptionType_Roles:
		sb.WriteString(" with role")
		for i, role := range gau.Roles {
			if i > 0 {
				sb.WriteRune(',')
			}
			sb.WriteRune(' ')
			sb.WriteString(role.String())
		}
	}
	return sb.String()
}

// CreateUser represents the CREATE USER statement.
type CreateUser struct {
	IfNotExists     bool
	Users           []AccountWithAuth
	DefaultRoles    []AccountName
	TLSOptions      *TLSOptions
	AccountLimits   *AccountLimits
	PasswordOptions *PasswordOptions
	Locked          bool
	Attribute       string
}

var _ Statement = (*CreateUser)(nil)

// iStatement implements the interface Statement.
func (c *CreateUser) iStatement() {}

// Format implements the interface Statement.
func (c *CreateUser) Format(buf *TrackedBuffer) {
	if c.IfNotExists {
		buf.Myprintf("create user if not exists")
	} else {
		buf.Myprintf("create user")
	}
	for i, user := range c.Users {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", user.String())
	}
	if len(c.DefaultRoles) > 0 {
		buf.Myprintf(" default role")
		for i, role := range c.DefaultRoles {
			if i > 0 {
				buf.Myprintf(",")
			}
			buf.Myprintf(" %s", role.String())
		}
	}
	if c.TLSOptions != nil {
		buf.Myprintf(" require ")
		buf.Myprintf(c.TLSOptions.String())
	}
	if c.AccountLimits != nil {
		buf.Myprintf(" with ")
		buf.Myprintf(c.AccountLimits.String())
	}
	if c.PasswordOptions != nil {
		buf.Myprintf(" %s", c.PasswordOptions.String())
	}
	if c.Locked {
		buf.Myprintf(" account lock")
	}
	if len(c.Attribute) > 0 {
		buf.Myprintf(" attribute '%s'", c.Attribute)
	}
}

// RenameUser represents the RENAME USER statement.
type RenameUser struct {
	Accounts []AccountRename
}

var _ Statement = (*RenameUser)(nil)

// iStatement implements the interface Statement.
func (r *RenameUser) iStatement() {}

// Format implements the interface Statement.
func (r *RenameUser) Format(buf *TrackedBuffer) {
	buf.Myprintf("rename user")
	for i, accountRename := range r.Accounts {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", accountRename.String())
	}
}

// DropUser represents the DROP USER statement.
type DropUser struct {
	IfExists     bool
	AccountNames []AccountName
}

var _ Statement = (*DropUser)(nil)

// iStatement implements the interface Statement.
func (d *DropUser) iStatement() {}

// Format implements the interface Statement.
func (d *DropUser) Format(buf *TrackedBuffer) {
	if d.IfExists {
		buf.Myprintf("drop user if exists")
	} else {
		buf.Myprintf("drop user")
	}
	for i, an := range d.AccountNames {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", an.String())
	}
}

// CreateRole represents the CREATE ROLE statement.
type CreateRole struct {
	IfNotExists bool
	Roles       []AccountName
}

var _ Statement = (*CreateRole)(nil)

// iStatement implements the interface Statement.
func (c *CreateRole) iStatement() {}

// Format implements the interface Statement.
func (c *CreateRole) Format(buf *TrackedBuffer) {
	if c.IfNotExists {
		buf.Myprintf("create role if not exists")
	} else {
		buf.Myprintf("create role")
	}
	for i, role := range c.Roles {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", role.String())
	}
}

// DropRole represents the DROP ROLE statement.
type DropRole struct {
	IfExists bool
	Roles    []AccountName
}

var _ Statement = (*DropRole)(nil)

// iStatement implements the interface Statement.
func (d *DropRole) iStatement() {}

// Format implements the interface Statement.
func (d *DropRole) Format(buf *TrackedBuffer) {
	if d.IfExists {
		buf.Myprintf("drop role if exists")
	} else {
		buf.Myprintf("drop role")
	}
	for i, role := range d.Roles {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", role.String())
	}
}

// GrantPrivilege represents the GRANT...ON...TO statement.
type GrantPrivilege struct {
	Privileges      []Privilege
	ObjectType      GrantObjectType
	PrivilegeLevel  PrivilegeLevel
	To              []AccountName
	WithGrantOption bool
	As              *GrantUserAssumption
}

var _ Statement = (*GrantPrivilege)(nil)

// iStatement implements the interface Statement.
func (g *GrantPrivilege) iStatement() {}

// Format implements the interface Statement.
func (g *GrantPrivilege) Format(buf *TrackedBuffer) {
	buf.Myprintf("grant")
	for i, privilege := range g.Privileges {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", privilege.String())
	}
	buf.Myprintf(" on")
	switch g.ObjectType {
	case GrantObjectType_Any:
		// Do nothing, here to explicitly list all cases
	case GrantObjectType_Table:
		buf.Myprintf(" table")
	case GrantObjectType_Function:
		buf.Myprintf(" function")
	case GrantObjectType_Procedure:
		buf.Myprintf(" procedure")
	}
	buf.Myprintf(" %s to", g.PrivilegeLevel.String())
	for i, user := range g.To {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", user.String())
	}
	if g.WithGrantOption {
		buf.Myprintf(" with grant option")
	}
	if g.As != nil {
		buf.Myprintf(" %s", g.As.String())
	}
}

// GrantRole represents the GRANT...TO statement.
type GrantRole struct {
	Roles           []AccountName
	To              []AccountName
	WithAdminOption bool
}

var _ Statement = (*GrantRole)(nil)

// iStatement implements the interface Statement.
func (g *GrantRole) iStatement() {}

// Format implements the interface Statement.
func (g *GrantRole) Format(buf *TrackedBuffer) {
	buf.Myprintf("grant")
	for i, role := range g.Roles {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", role.String())
	}
	buf.Myprintf(" to")
	for i, user := range g.To {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", user.String())
	}
	if g.WithAdminOption {
		buf.Myprintf(" with admin option")
	}
}

// GrantProxy represents the GRANT PROXY statement.
type GrantProxy struct {
	On              AccountName
	To              []AccountName
	WithGrantOption bool
}

var _ Statement = (*GrantProxy)(nil)

// iStatement implements the interface Statement.
func (g *GrantProxy) iStatement() {}

// Format implements the interface Statement.
func (g *GrantProxy) Format(buf *TrackedBuffer) {
	buf.Myprintf("grant proxy on %s to", g.On.String())
	for i, user := range g.To {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", user.String())
	}
	if g.WithGrantOption {
		buf.Myprintf(" with grant option")
	}
}

// RevokePrivilege represents the REVOKE...ON...FROM statement.
type RevokePrivilege struct {
	Privileges     []Privilege
	ObjectType     GrantObjectType
	PrivilegeLevel PrivilegeLevel
	From           []AccountName
}

var _ Statement = (*RevokePrivilege)(nil)

// iStatement implements the interface Statement.
func (r *RevokePrivilege) iStatement() {}

// Format implements the interface Statement.
func (r *RevokePrivilege) Format(buf *TrackedBuffer) {
	buf.Myprintf("revoke")
	for i, privilege := range r.Privileges {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", privilege.String())
	}
	buf.Myprintf(" on")
	switch r.ObjectType {
	case GrantObjectType_Any:
		// Do nothing, here to explicitly list all cases
	case GrantObjectType_Table:
		buf.Myprintf(" table")
	case GrantObjectType_Function:
		buf.Myprintf(" function")
	case GrantObjectType_Procedure:
		buf.Myprintf(" procedure")
	}
	buf.Myprintf(" %s from", r.PrivilegeLevel.String())
	for i, user := range r.From {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", user.String())
	}
}

// RevokeAllPrivileges represents the REVOKE ALL statement.
type RevokeAllPrivileges struct {
	From []AccountName
}

var _ Statement = (*RevokeAllPrivileges)(nil)

// iStatement implements the interface Statement.
func (r *RevokeAllPrivileges) iStatement() {}

// Format implements the interface Statement.
func (r *RevokeAllPrivileges) Format(buf *TrackedBuffer) {
	buf.Myprintf("revoke all privileges, grant option from")
	for i, user := range r.From {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", user.String())
	}
}

// RevokeRole represents the REVOKE...FROM statement.
type RevokeRole struct {
	Roles []AccountName
	From  []AccountName
}

var _ Statement = (*RevokeRole)(nil)

// iStatement implements the interface Statement.
func (r *RevokeRole) iStatement() {}

// Format implements the interface Statement.
func (r *RevokeRole) Format(buf *TrackedBuffer) {
	buf.Myprintf("revoke")
	for i, role := range r.Roles {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", role.String())
	}
	buf.Myprintf(" from")
	for i, user := range r.From {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", user.String())
	}
}

// RevokeProxy represents the REVOKE PROXY statement.
type RevokeProxy struct {
	On   AccountName
	From []AccountName
}

var _ Statement = (*RevokeProxy)(nil)

// iStatement implements the interface Statement.
func (r *RevokeProxy) iStatement() {}

// Format implements the interface Statement.
func (r *RevokeProxy) Format(buf *TrackedBuffer) {
	buf.Myprintf("revoke proxy on %s from", r.On.String())
	for i, user := range r.From {
		if i > 0 {
			buf.Myprintf(",")
		}
		buf.Myprintf(" %s", user.String())
	}
}

// ShowGrants represents the SHOW GRANTS statement.
type ShowGrants struct {
	CurrentUser bool
	For         *AccountName
	Using       []AccountName
}

var _ Statement = (*ShowGrants)(nil)

// iStatement implements the interface Statement.
func (s *ShowGrants) iStatement() {}

// Format implements the interface Statement.
func (s *ShowGrants) Format(buf *TrackedBuffer) {
	buf.Myprintf("show grants")
	if s.CurrentUser || s.For != nil {
		if s.CurrentUser {
			buf.Myprintf(" for Current_User()")
		} else {
			buf.Myprintf(" for %s", s.For.String())
		}
		if len(s.Using) > 0 {
			buf.Myprintf(" using")
			for i, using := range s.Using {
				if i > 0 {
					buf.Myprintf(",")
				}
				buf.Myprintf(" %s", using.String())
			}
		}
	}
}

// ShowPrivileges represents the SHOW PRIVILEGES statement.
type ShowPrivileges struct{}

var _ Statement = (*ShowPrivileges)(nil)

// iStatement implements the interface Statement.
func (s *ShowPrivileges) iStatement() {}

// Format implements the interface Statement.
func (s *ShowPrivileges) Format(buf *TrackedBuffer) {
	buf.Myprintf("show privileges")
}

// atoi is a shortcut for converting integer SQLVals to integers.
func atoi(val *SQLVal) int {
	if val == nil {
		return 0
	}
	i, _ := strconv.Atoi(val.String())
	return i
}

// escapeDoubleQuotes escapes any double quotes.
func escapeDoubleQuotes(str string) string {
	return strings.ReplaceAll(str, `"`, `\"`)
}
