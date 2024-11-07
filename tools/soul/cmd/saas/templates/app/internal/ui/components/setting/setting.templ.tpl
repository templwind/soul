package setting

templ tpl(props *Props) {
	<div class="flex flex-row justify-between form-control" id={ "notification-setting-" + props.Setting.Key }>
		<div class="label">
			<span class="label-text">
				<span class="font-semibold">{ props.Setting.Name }</span>
				<br/>
				<span class="text-sm text-gray-600">{ props.Setting.Description }</span>
			</span>
		</div>
		<div>
			switch props.Setting.Kind {
				case "boolean":
					<input
						type="checkbox"
						class={ "toggle toggle-success", props.Setting.Color }
						checked?={ props.Setting.Value == "true" }
						hx-post={ "/app/settings/toggle/" + props.Setting.Scope + "/" + props.Setting.Key }
						disabled?={ props.Setting.Disabled }
					/>
				case "text":
					<input
						type="text"
						name="item"
						class="w-full input input-bordered"
						value={ props.Setting.Value }
						hx-post={ "/app/settings/update/" + props.Setting.Scope + "/" + props.Setting.Key }
						hx-trigger="change"
						disabled?={ props.Setting.Disabled }
					/>
				case "number":
					<input
						type="number"
						name="item"
						class="w-full input input-bordered"
						value={ props.Setting.Value }
						hx-post={ "/app/settings/update/" + props.Setting.Scope + "/" + props.Setting.Key }
						hx-trigger="change"
						disabled?={ props.Setting.Disabled }
					/>
				case "password":
					<input
						type="password"
						name="item"
						class="w-full input input-bordered"
						value={ props.Setting.Value }
						hx-post={ "/app/settings/update/" + props.Setting.Scope + "/" + props.Setting.Key }
						hx-trigger="change"
						disabled?={ props.Setting.Disabled }
					/>
				case "select":
					<select
						name="item"
						class="w-full select select-bordered"
						hx-post={ "/app/settings/update/" + props.Setting.Scope + "/" + props.Setting.Key }
						hx-trigger="change"
						disabled?={ props.Setting.Disabled }
					>
						for _, option := range props.Setting.Options {
							<option value={ option } selected?={ props.Setting.Value == option }>{ option }</option>
						}
					</select>
				default:
					<p class="text-sm text-gray-500">Unsupported setting type: { props.Setting.Kind }</p>
			}
		</div>
	</div>
}
